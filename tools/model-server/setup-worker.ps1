# Nối máy GPU với Supabase theo kiểu "tự đi lấy câu hỏi":
#   ask-embrace --> hàng chờ ai_jobs <-- model-worker.ps1 (máy này) --> Ollama
# Máy này chỉ đi ra internet, không mở cổng nào. Bộ cài cũng gỡ Funnel và Caddy
# của cách làm trước. Chạy qua 2-CONNECT-TO-SUPABASE.bat; chạy lại bao nhiêu lần
# cũng được.
$ErrorActionPreference = 'Stop'

# Cần quyền Administrator để cài chương trình chạy nền và gỡ Funnel.
$principal = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell -Verb RunAs -Wait -ArgumentList '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', "`"$PSCommandPath`""
    exit
}

Start-Transcript -Path (Join-Path $PSScriptRoot 'worker-setup-log.txt') -Append | Out-Null
function Step($text) { Write-Host "`n== $text" -ForegroundColor Cyan }
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

try {
    $keyFile = Join-Path $PSScriptRoot 'server-key.txt'
    $urlFile = Join-Path $PSScriptRoot 'supabase-url.txt'
    if (-not (Test-Path $keyFile) -or -not (Test-Path $urlFile)) {
        throw 'server-key.txt or supabase-url.txt is missing: run new-key.ps1 on the development machine and copy the new kit.'
    }
    $key = (Get-Content $keyFile -Raw).Trim()
    if ($key -notmatch '^[0-9a-f]{64}$') { throw 'server-key.txt does not contain a valid key.' }
    $supabaseUrl = (Get-Content $urlFile -Raw).Trim().TrimEnd('/')
    if ($supabaseUrl -notmatch '^https://[a-z0-9]+\.supabase\.co$') { throw 'supabase-url.txt does not contain a Supabase address.' }
    $dir = 'C:\ProgramData\EmbraceAI'
    New-Item -ItemType Directory -Force -Path $dir | Out-Null

    Step '1/4 Check that the model is running on this PC'
    try {
        $tags = Invoke-RestMethod 'http://127.0.0.1:11434/api/tags' -TimeoutSec 10
    } catch {
        throw 'Ollama is not running. Open the Ollama app from the Start menu, then run this again.'
    }
    Write-Host "Models: $(($tags.models | ForEach-Object { $_.name }) -join ', ')"
    $parallel = [Environment]::GetEnvironmentVariable('OLLAMA_NUM_PARALLEL', 'User')
    if ($parallel -ne '4') {
        Write-Warning 'Ollama answers one question at a time. Run START-HERE.bat again (or set OLLAMA_NUM_PARALLEL to 4) and restart Ollama.'
    }

    Step '2/4 Remove the old public address (Funnel and the Caddy gatekeeper)'
    $ts = 'C:\Program Files\Tailscale\tailscale.exe'
    if (Test-Path $ts) {
        # tailscale báo lỗi ra stderr khi Funnel vốn đã tắt; điều đó không sao.
        $ErrorActionPreference = 'Continue'
        & $ts funnel --https=443 off 2>&1 | Out-Null
        $ErrorActionPreference = 'Stop'
    }
    Unregister-ScheduledTask -TaskName 'EmbraceAI model gatekeeper' -Confirm:$false -ErrorAction SilentlyContinue
    Get-Process caddy -ErrorAction SilentlyContinue | Stop-Process -Force
    Start-Sleep -Seconds 1
    Remove-Item (Join-Path $dir 'caddy.exe'), (Join-Path $dir 'Caddyfile') -Force -ErrorAction SilentlyContinue
    Write-Host 'This PC no longer has a public address.'

    Step '3/4 Install the worker that fetches questions from Supabase'
    $test = @{ action = 'status' } | ConvertTo-Json -Compress
    try {
        Invoke-RestMethod "$supabaseUrl/functions/v1/ai-worker" -Method Post -Body $test -ContentType 'application/json' -Headers @{ Authorization = "Bearer $key" } -TimeoutSec 20 | Out-Null
    } catch {
        $code = $_.Exception.Response.StatusCode.value__
        if ($code -eq 401) { throw 'Supabase does not accept this key: run new-key.ps1 again and copy the new kit.' }
        if ($code -eq 404) { throw 'The ai-worker function is not deployed yet: deploy it, then run this again.' }
        throw "Cannot reach Supabase: $($_.Exception.Message)"
    }
    Write-Host 'Supabase accepts the key.'

    $taskName = 'EmbraceAI model worker'
    Stop-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue
    Copy-Item (Join-Path $PSScriptRoot 'model-worker.ps1') $dir -Force
    [IO.File]::WriteAllText((Join-Path $dir 'supabase-url.txt'), $supabaseUrl)
    $workerKey = Join-Path $dir 'worker-key.txt'
    [IO.File]::WriteAllText($workerKey, $key)
    # Chỉ Administrator và SYSTEM đọc được file chứa khoá.
    icacls $workerKey /inheritance:r /grant:r 'Administrators:F' 'SYSTEM:F' | Out-Null

    $script = Join-Path $dir 'model-worker.ps1'
    $action = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$script`""
    $trigger = New-ScheduledTaskTrigger -AtStartup
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -ExecutionTimeLimit ([TimeSpan]::Zero) -RestartCount 999 -RestartInterval (New-TimeSpan -Minutes 1)
    Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Settings $settings -User 'SYSTEM' -RunLevel Highest | Out-Null
    Start-ScheduledTask -TaskName $taskName

    Step '4/4 Check that the worker reaches Supabase'
    $seen = $null
    for ($i = 0; $i -lt 6 -and $null -eq $seen; $i++) {
        Start-Sleep -Seconds 5
        $status = Invoke-RestMethod "$supabaseUrl/functions/v1/ai-worker" -Method Post -Body $test -ContentType 'application/json' -Headers @{ Authorization = "Bearer $key" } -TimeoutSec 20
        if ($null -ne $status.seconds_since_seen -and $status.seconds_since_seen -le 30) { $seen = $status.seconds_since_seen }
    }
    if ($null -eq $seen) {
        $log = Join-Path $dir 'worker-log.txt'
        if (Test-Path $log) { Get-Content $log -Tail 10 | Write-Host }
        throw 'The worker started but has not reached Supabase yet.'
    }
    Write-Host "The worker checked in $seen seconds ago."
    Write-Host "`nDONE. Questions from the app now reach the model on this PC." -ForegroundColor Green
    Write-Host 'You can delete this folder and the zip: the key is kept in C:\ProgramData\EmbraceAI.' -ForegroundColor Yellow
}
catch {
    Write-Host "`nFAILED: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host 'Send worker-setup-log.txt (next to this script) to Claude. It does not contain the key.'
}
finally {
    Stop-Transcript | Out-Null
    Read-Host 'Press Enter to close'
}
