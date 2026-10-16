# Chạy nền trên máy GPU (task "EmbraceAI model worker", cài bằng
# 2-CONNECT-TO-SUPABASE.bat): hỏi Supabase xem có câu hỏi mới không, đưa cho
# Ollama trả lời rồi gửi kết quả về. Máy này chỉ đi ra internet như một trình
# duyệt, không mở cổng nào. Nhật ký không ghi nội dung câu hỏi.
#
# Khi Whisper (whisper-server, cài bằng 3-ADD-SPEECH-TO-TEXT.bat) đang chạy
# trên máy này, chương trình nhận thêm việc "transcribe": tải đoạn ghi âm về,
# đưa cho Whisper rồi gửi chữ về. Đoạn ghi âm bị xoá ngay sau đó.
#
# Giữ tối đa $Slots câu cùng lúc, khớp với OLLAMA_NUM_PARALLEL: mỗi câu chạy
# trong một luồng riêng (gọi Ollama rồi tự gửi kết quả), còn vòng chính chỉ
# lấy thêm việc khi có chỗ trống.
param(
    [string]$ConfigDir = $PSScriptRoot,
    [string]$OllamaUrl = 'http://127.0.0.1:11434',
    [string]$WhisperUrl = 'http://127.0.0.1:8178',
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

# Số đo của máy (nvidia-smi và CPU mà Ollama dùng), đọc 5 giây một lần trên một
# luồng riêng để không làm chậm việc lấy câu hỏi. Mỗi số đo chỉ gửi kèm một lần
# hỏi việc, lúc nó còn mới: bài đo sức chứa (tools/ai-lab/capacity.mjs) dựa vào
# đó để biết GPU đã làm hết sức chưa. Máy không có nvidia-smi thì bỏ phần GPU.
$readStats = {
    param($box, $slots)
    $smi = (Get-Command nvidia-smi -ErrorAction SilentlyContinue).Source
    $smiDefault = 'C:\Program Files\NVIDIA Corporation\NVSMI\nvidia-smi.exe'
    if (-not $smi -and (Test-Path $smiDefault)) { $smi = $smiDefault }
    $names = 'gpu_util', 'gpu_mem_busy', 'gpu_mem_used_mb', 'gpu_mem_total_mb', 'gpu_power_w', 'gpu_power_limit_w',
        'gpu_clock_mhz', 'gpu_clock_max_mhz', 'gpu_temp_c'
    $lastCpu = $null
    $lastAt = $null
    while ($true) {
        $fresh = @{ slots = $slots; cpu_count = [Environment]::ProcessorCount }
        if ($smi) {
            try {
                $line = & $smi '--query-gpu=utilization.gpu,utilization.memory,memory.used,memory.total,power.draw,power.limit,clocks.sm,clocks.max.sm,temperature.gpu' '--format=csv,noheader,nounits' |
                    Select-Object -First 1
                $values = "$line" -split ','
                for ($i = 0; $i -lt $names.Count -and $i -lt $values.Count; $i++) {
                    $number = 0.0
                    # Vài GPU ghi "[N/A]" cho một số mục: bỏ qua mục đó.
                    if ([double]::TryParse($values[$i].Trim(), [Globalization.NumberStyles]::Float,
                            [Globalization.CultureInfo]::InvariantCulture, [ref]$number)) {
                        $fresh[$names[$i]] = $number
                    }
                }
            } catch { }
        }
        # Ollama dùng bao nhiêu nhân CPU từ lần đọc trước (1 = trọn một nhân).
        $now = Get-Date
        $cpu = 0.0
        foreach ($process in @(Get-Process -Name 'ollama*' -ErrorAction SilentlyContinue)) {
            try { $cpu += $process.TotalProcessorTime.TotalSeconds } catch { }
        }
        if ($null -ne $lastCpu -and $cpu -ge $lastCpu) {
            $fresh.ollama_cpu_cores = [Math]::Round(($cpu - $lastCpu) / ($now - $lastAt).TotalSeconds, 2)
        }
        $lastCpu = $cpu
        $lastAt = $now
        $box.stats = $fresh
        $box.seq++
        Start-Sleep -Seconds 5
    }
}
$statsBox = [hashtable]::Synchronized(@{ seq = 0; stats = $null })
$statsShell = [PowerShell]::Create()
[void]$statsShell.AddScript($readStats).AddArgument($statsBox).AddArgument($Slots)
[void]$statsShell.BeginInvoke()
# Đợi lần đọc đầu (tối đa 5 giây) để lần hỏi việc đầu tiên đã báo số chỗ.
for ($i = 0; $i -lt 50 -and $statsBox.seq -eq 0; $i++) { Start-Sleep -Milliseconds 100 }
$sentSeq = 0

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

# Một đoạn ghi âm: tải WAV từ Supabase, đưa cho whisper-server, gửi chữ về.
# curl.exe (có sẵn từ Windows 10 1803) gửi file dạng multipart, việc mà
# Invoke-RestMethod của PowerShell 5.1 không làm được. Kết quả đọc từ file theo
# UTF-8, vì đọc thẳng từ curl thì PowerShell làm hỏng chữ có dấu.
$transcribeOne = {
    param($id, $language, $endpoint, $key, $whisperUrl)
    $ErrorActionPreference = 'Stop'
    function Post($payload) {
        $bytes = [Text.Encoding]::UTF8.GetBytes(($payload | ConvertTo-Json -Compress))
        Invoke-RestMethod $endpoint -Method Post -Body $bytes -TimeoutSec 30 -DisableKeepAlive `
            -ContentType 'application/json; charset=utf-8' -Headers @{ Authorization = "Bearer $key" } | Out-Null
    }
    $started = Get-Date
    $wav = Join-Path $env:TEMP "embrace-$id.wav"
    $out = Join-Path $env:TEMP "embrace-$id.json"
    try {
        $request = [Text.Encoding]::UTF8.GetBytes((@{ action = 'audio'; id = $id } | ConvertTo-Json -Compress))
        Invoke-WebRequest $endpoint -Method Post -Body $request -OutFile $wav -TimeoutSec 30 -DisableKeepAlive -UseBasicParsing `
            -ContentType 'application/json; charset=utf-8' -Headers @{ Authorization = "Bearer $key" }
        & curl.exe -s -S --max-time 40 -o $out -F "file=@$wav" -F "language=$language" -F 'response_format=json' `
            -F 'temperature=0' "$whisperUrl/inference"
        if ($LASTEXITCODE -ne 0) { throw "whisper-server did not answer (curl exit $LASTEXITCODE)" }
        $reply = [IO.File]::ReadAllText($out, [Text.Encoding]::UTF8) | ConvertFrom-Json
        if ($null -ne $reply.error) { throw "whisper-server: $($reply.error)" }
        Post @{ action = 'result'; id = $id; content = [string]$reply.text }
        "Transcribed $id in $([int]((Get-Date) - $started).TotalMilliseconds) ms"
    } catch {
        $reason = "$($_.Exception.Message)"
        try { Post @{ action = 'fail'; id = $id; error = $reason } } catch { }
        "Could not transcribe ${id}: $reason"
    } finally {
        Remove-Item $wav, $out -Force -ErrorAction SilentlyContinue
    }
}

# Whisper có đang chạy không: hỏi lại mỗi phút, để cài hay tắt Whisper thì chương
# trình tự biết mà không phải khởi động lại.
function SpeechReady {
    try {
        Invoke-WebRequest "$WhisperUrl/" -UseBasicParsing -TimeoutSec 3 -DisableKeepAlive | Out-Null
        return $true
    } catch { return $false }
}
$speech = SpeechReady
$speechCheckedAt = Get-Date

$pool = [RunspaceFactory]::CreateRunspacePool(1, $Slots)
$pool.Open()
$running = New-Object System.Collections.ArrayList
$handled = 0

Log "Worker started with $Slots slots; speech to text $(if ($speech) { 'on' } else { 'off' })"
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
        if (((Get-Date) - $speechCheckedAt).TotalSeconds -ge 60) {
            $now = SpeechReady
            if ($now -ne $speech) { Log "Speech to text is now $(if ($now) { 'on' } else { 'off' })" }
            $speech = $now
            $speechCheckedAt = Get-Date
        }
        $kinds = if ($speech) { @('chat', 'transcribe') } else { @('chat') }
        $payload = @{ action = 'next'; max = $free; kinds = $kinds }
        if ($statsBox.seq -ne $sentSeq) { $payload.stats = $statsBox.stats; $sentSeq = $statsBox.seq }
        $reply = Send $payload 35
        if ($offline) { Log 'Supabase reachable again'; $offline = $false }
        # ai-worker bản cũ chưa biết "max": trả một việc theo khuôn cũ.
        $jobs = if ($null -ne $reply.jobs) { @($reply.jobs) } elseif ($reply.id) { @($reply) } else { @() }
        foreach ($job in $jobs) {
            $shell = [PowerShell]::Create()
            $shell.RunspacePool = $pool
            if ($job.kind -eq 'transcribe') {
                [void]$shell.AddScript($transcribeOne).AddArgument($job.id).AddArgument($job.language).AddArgument($endpoint).AddArgument($key).AddArgument($WhisperUrl)
            } else {
                [void]$shell.AddScript($answerOne).AddArgument($job.id).AddArgument($job.body).AddArgument($endpoint).AddArgument($key).AddArgument($OllamaUrl)
            }
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
$statsShell.Stop()
$statsShell.Dispose()
$pool.Close()
