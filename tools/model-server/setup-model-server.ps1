# Turns this PC into the EmbraceAI model server, reachable only inside the
# owner's Tailscale network. Run it once, on the GPU machine, via START-HERE.bat.
param([string]$Model = 'gpt-oss:20b')

$ErrorActionPreference = 'Stop'
Start-Transcript -Path (Join-Path $PSScriptRoot 'setup-log.txt') -Append | Out-Null

function Step($text) { Write-Host "`n== $text" -ForegroundColor Cyan }

try {
    Step '1/6 GPU'
    try { nvidia-smi --query-gpu=name,memory.total --format=csv,noheader }
    catch { Write-Warning 'nvidia-smi not found: check that the NVIDIA driver is installed.' }

    Step '2/6 Install Ollama'
    $ollamaDir = Join-Path $env:LOCALAPPDATA 'Programs\Ollama'
    $ollama = Join-Path $ollamaDir 'ollama.exe'
    if (Test-Path $ollama) {
        Write-Host 'Ollama is already installed.'
    } elseif (Get-Command winget -ErrorAction SilentlyContinue) {
        winget install --id Ollama.Ollama -e --silent --accept-source-agreements --accept-package-agreements
    } else {
        $setup = Join-Path $env:TEMP 'OllamaSetup.exe'
        Invoke-WebRequest 'https://ollama.com/download/OllamaSetup.exe' -OutFile $setup
        Start-Process $setup -ArgumentList '/SILENT' -Wait
    }
    if (-not (Test-Path $ollama)) { throw 'Ollama did not install. Install it from ollama.com, then run this again.' }

    Step '3/6 Listen on the network, keep the model loaded, answer 16 at once'
    # The server only answers other machines once OLLAMA_HOST is 0.0.0.0;
    # the firewall rule in step 5 limits that to Tailscale addresses.
    [Environment]::SetEnvironmentVariable('OLLAMA_HOST', '0.0.0.0:11434', 'User')
    [Environment]::SetEnvironmentVariable('OLLAMA_KEEP_ALIVE', '24h', 'User')
    # Đo trên RTX 5060 Ti 16 GB, mỗi câu hỏi một khác: khoảng 42 câu mỗi phút khi
    # từng câu một, 61-70 khi 4 câu, 74 khi 8 câu, 81 khi 16 câu; thêm nữa gần như
    # không nhanh hơn. setup-worker.ps1 cho model-worker.ps1 giữ đúng số này.
    [Environment]::SetEnvironmentVariable('OLLAMA_NUM_PARALLEL', '16', 'User')
    Get-Process 'ollama app', 'ollama' -ErrorAction SilentlyContinue | Stop-Process -Force
    $env:OLLAMA_HOST = '0.0.0.0:11434'
    $env:OLLAMA_KEEP_ALIVE = '24h'
    $env:OLLAMA_NUM_PARALLEL = '16'
    Start-Process (Join-Path $ollamaDir 'ollama app.exe')
    $env:OLLAMA_HOST = '127.0.0.1:11434'
    $up = $false
    for ($i = 0; $i -lt 30 -and -not $up; $i++) {
        try { Invoke-RestMethod 'http://127.0.0.1:11434/api/version' | Out-Null; $up = $true }
        catch { Start-Sleep -Seconds 2 }
    }
    if (-not $up) { throw 'The Ollama server did not start.' }

    Step "4/6 Download $Model (about 14 GB, this takes a while)"
    & $ollama pull $Model
    if ($LASTEXITCODE -ne 0) { throw "Could not download $Model." }

    Step '5/6 Firewall, sleep and Tailscale (Windows will ask for administrator approval)'
    $adminScript = @'
if (-not (Get-NetFirewallRule -DisplayName 'Ollama via Tailscale' -ErrorAction SilentlyContinue)) {
    New-NetFirewallRule -DisplayName 'Ollama via Tailscale' -Direction Inbound -Protocol TCP -LocalPort 11434 -RemoteAddress 100.64.0.0/10 -Action Allow -Profile Any | Out-Null
}
powercfg /change standby-timeout-ac 0
powercfg /change hibernate-timeout-ac 0
$ts = 'C:\Program Files\Tailscale\tailscale.exe'
if (Test-Path $ts) { & $ts set --unattended=true }
'@
    $encoded = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($adminScript))
    Start-Process powershell -Verb RunAs -Wait -ArgumentList '-NoProfile', '-EncodedCommand', $encoded
    if (Get-NetFirewallRule -DisplayName 'Ollama via Tailscale' -ErrorAction SilentlyContinue) {
        Write-Host 'Firewall rule is in place.'
    } else {
        Write-Warning 'Firewall rule missing: an administrator must approve step 5.'
    }

    Step '6/6 Test'
    $body = @{ model = $Model; prompt = 'Reply with the single word: ready'; stream = $false } | ConvertTo-Json
    $reply = Invoke-RestMethod 'http://127.0.0.1:11434/api/generate' -Method Post -Body $body -ContentType 'application/json'
    Write-Host "Model replied: $($reply.response)"
    try { nvidia-smi --query-gpu=memory.used,memory.total --format=csv,noheader } catch {}
    $ip = 'unknown'
    try { $ip = (& 'C:\Program Files\Tailscale\tailscale.exe' ip -4) } catch {}
    Write-Host "`nDONE. Leave this PC switched on. Tailscale address: $ip  port 11434" -ForegroundColor Green
}
catch {
    Write-Host "`nFAILED: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host 'Send setup-log.txt (next to this script) to Claude.'
}
finally {
    Stop-Transcript | Out-Null
}
