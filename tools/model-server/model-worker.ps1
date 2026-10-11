# Chạy nền trên máy GPU (task "EmbraceAI model worker", cài bằng
# 2-CONNECT-TO-SUPABASE.bat): hỏi Supabase xem có câu hỏi mới không, đưa cho
# Ollama trả lời rồi gửi kết quả về. Máy này chỉ đi ra internet như một trình
# duyệt, không mở cổng nào. Nhật ký không ghi nội dung câu hỏi.
#
# Giữ tối đa $Slots câu cùng lúc, khớp với OLLAMA_NUM_PARALLEL: mỗi câu chạy
# trong một luồng riêng (gọi Ollama rồi tự gửi kết quả), còn vòng chính chỉ
# lấy thêm việc khi có chỗ trống.
param(
    [string]$ConfigDir = $PSScriptRoot,
    [string]$OllamaUrl = 'http://127.0.0.1:11434',
    [int]$Slots = 4,
    # Chỉ dùng khi thử: dừng sau chừng này câu.
    [int]$StopAfter = 0
)
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
[Net.ServicePointManager]::DefaultConnectionLimit = [Math]::Max(10, $Slots * 2)

$key = (Get-Content (Join-Path $ConfigDir 'worker-key.txt') -Raw).Trim()
$supabaseUrl = (Get-Content (Join-Path $ConfigDir 'supabase-url.txt') -Raw).Trim().TrimEnd('/')
$endpoint = "$supabaseUrl/functions/v1/ai-worker"
$logFile = Join-Path $ConfigDir 'worker-log.txt'

function Log($text) {
    if ((Test-Path $logFile) -and (Get-Item $logFile).Length -gt 1MB) {
        Move-Item $logFile "$logFile.old" -Force
    }
    Add-Content $logFile "$(Get-Date -Format s) $text"
}

# Gửi JSON dạng UTF-8: PowerShell 5.1 mặc định làm hỏng chữ có dấu. Mỗi lần
# gọi Supabase dùng kết nối mới: PowerShell 5.1 hay dùng lại một kết nối máy chủ
# đã đóng rồi treo ("The underlying connection was closed"), làm mất câu vừa nhận.
function Send($payload, $timeoutSec) {
    $bytes = [Text.Encoding]::UTF8.GetBytes(($payload | ConvertTo-Json -Compress))
    Invoke-RestMethod $endpoint -Method Post -Body $bytes -TimeoutSec $timeoutSec -DisableKeepAlive `
        -ContentType 'application/json; charset=utf-8' -Headers @{ Authorization = "Bearer $key" }
}

# Một câu: gọi Ollama, gửi kết quả (hoặc báo lỗi) về Supabase, trả về một dòng nhật ký.
$answerOne = {
    param($id, $body, $endpoint, $key, $ollamaUrl)
    $ErrorActionPreference = 'Stop'
    function Post($payload) {
        $bytes = [Text.Encoding]::UTF8.GetBytes(($payload | ConvertTo-Json -Compress))
        Invoke-RestMethod $endpoint -Method Post -Body $bytes -TimeoutSec 30 -DisableKeepAlive `
            -ContentType 'application/json; charset=utf-8' -Headers @{ Authorization = "Bearer $key" } | Out-Null
    }
    $started = Get-Date
    try {
        $reply = Invoke-RestMethod "$ollamaUrl/api/chat" -Method Post -TimeoutSec 90 `
            -Body ([Text.Encoding]::UTF8.GetBytes($body)) -ContentType 'application/json; charset=utf-8'
        Post @{ action = 'result'; id = $id; content = [string]$reply.message.content }
        "Answered $id in $([int]((Get-Date) - $started).TotalMilliseconds) ms"
    } catch {
        $reason = "$($_.Exception.Message)"
        try { Post @{ action = 'fail'; id = $id; error = $reason } } catch { }
        "Could not answer ${id}: $reason"
    }
}

$pool = [RunspaceFactory]::CreateRunspacePool(1, $Slots)
$pool.Open()
$running = New-Object System.Collections.ArrayList
$handled = 0

Log "Worker started with $Slots slots"
$offline = $false
while ($StopAfter -eq 0 -or $handled -lt $StopAfter -or $running.Count -gt 0) {
    # Thu các câu đã xong và ghi nhật ký.
    foreach ($task in @($running)) {
        if (-not $task.Handle.IsCompleted) { continue }
        try { Log ([string]($task.Shell.EndInvoke($task.Handle) -join ' ')) }
        catch { Log "Slot error for $($task.Id): $($_.Exception.Message)" }
        finally { $task.Shell.Dispose(); $running.Remove($task) }
    }

    $free = $Slots - $running.Count
    if ($StopAfter -gt 0) { $free = [Math]::Min($free, $StopAfter - $handled) }
    if ($free -le 0) { Start-Sleep -Milliseconds 200; continue }

    try {
        # ai-worker giữ yêu cầu tối đa 20 giây; quá 35 giây là kết nối có vấn đề.
        $reply = Send @{ action = 'next'; max = $free } 35
        if ($offline) { Log 'Supabase reachable again'; $offline = $false }
        # ai-worker bản cũ chưa biết "max": trả một việc theo khuôn cũ.
        $jobs = if ($null -ne $reply.jobs) { @($reply.jobs) } elseif ($reply.id) { @($reply) } else { @() }
        foreach ($job in $jobs) {
            $shell = [PowerShell]::Create()
            $shell.RunspacePool = $pool
            [void]$shell.AddScript($answerOne).AddArgument($job.id).AddArgument($job.body).AddArgument($endpoint).AddArgument($key).AddArgument($OllamaUrl)
            [void]$running.Add([pscustomobject]@{ Id = $job.id; Shell = $shell; Handle = $shell.BeginInvoke() })
            $handled++
        }
    } catch {
        # Lần đứt đầu thường chỉ là một kết nối hỏng: thử lại ngay. Đứt liên tục
        # (mất mạng) thì chờ lâu hơn. Câu nhận dở sẽ được Supabase trả lại hàng chờ.
        $retrySeconds = if ($offline) { 5 } else { 1 }
        if (-not $offline) { Log "Cannot reach Supabase: $($_.Exception.Message)"; $offline = $true }
        Start-Sleep -Seconds $retrySeconds
    }
}
$pool.Close()
