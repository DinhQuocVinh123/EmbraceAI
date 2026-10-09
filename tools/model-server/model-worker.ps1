# Chạy nền trên máy GPU (task "EmbraceAI model worker", cài bằng
# 2-CONNECT-TO-SUPABASE.bat): hỏi Supabase xem có câu hỏi mới không, đưa cho
# Ollama trả lời rồi gửi kết quả về. Máy này chỉ đi ra internet như một trình
# duyệt, không mở cổng nào. Nhật ký không ghi nội dung câu hỏi.
param(
    [string]$ConfigDir = $PSScriptRoot,
    [string]$OllamaUrl = 'http://127.0.0.1:11434',
    # Chỉ dùng khi thử: xử lý một việc rồi dừng.
    [switch]$Once
)
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

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

# Gửi JSON dạng UTF-8: PowerShell 5.1 mặc định làm hỏng chữ có dấu.
function Send($payload, $timeoutSec) {
    $bytes = [Text.Encoding]::UTF8.GetBytes(($payload | ConvertTo-Json -Compress))
    Invoke-RestMethod $endpoint -Method Post -Body $bytes -TimeoutSec $timeoutSec `
        -ContentType 'application/json; charset=utf-8' -Headers @{ Authorization = "Bearer $key" }
}

Log 'Worker started'
$offline = $false
while ($true) {
    try {
        $job = Send @{ action = 'next' } 60
        if ($offline) { Log 'Supabase reachable again'; $offline = $false }
        if (-not $job.id) { continue }

        $started = Get-Date
        try {
            $reply = Invoke-RestMethod "$OllamaUrl/api/chat" -Method Post -TimeoutSec 90 `
                -Body ([Text.Encoding]::UTF8.GetBytes($job.body)) -ContentType 'application/json; charset=utf-8'
            Send @{ action = 'result'; id = $job.id; content = [string]$reply.message.content } 30 | Out-Null
            Log "Answered $($job.id) in $([int]((Get-Date) - $started).TotalMilliseconds) ms"
        } catch {
            $reason = "$($_.Exception.Message)"
            Send @{ action = 'fail'; id = $job.id; error = $reason } 30 | Out-Null
            Log "Could not answer $($job.id): $reason"
        }
        if ($Once) { break }
    } catch {
        if (-not $offline) { Log "Cannot reach Supabase: $($_.Exception.Message)"; $offline = $true }
        Start-Sleep -Seconds 5
    }
}
