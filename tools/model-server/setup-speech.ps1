# Thêm "nói thay vì gõ" cho máy GPU: cài whisper.cpp (Whisper large-v3-turbo)
# chạy nền ở 127.0.0.1:8178, rồi cập nhật chương trình chạy nền để nó nhận cả
# việc chuyển giọng nói thành chữ. Whisper chỉ nghe trong máy này, không mở cổng
# nào ra ngoài. Chạy qua 3-ADD-SPEECH-TO-TEXT.bat sau 2-CONNECT-TO-SUPABASE.bat;
# chạy lại bao nhiêu lần cũng được.
$ErrorActionPreference = 'Stop'

$principal = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell -Verb RunAs -Wait -ArgumentList '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', "`"$PSCommandPath`""
    exit
}

Start-Transcript -Path (Join-Path $PSScriptRoot 'speech-setup-log.txt') -Append | Out-Null
function Step($text) { Write-Host "`n== $text" -ForegroundColor Cyan }
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

# Bản whisper.cpp và model cố định, kèm mã kiểm tra SHA-256: tải về mà sai một
# byte là dừng. Bản CUDA 12.4 đã gồm sẵn thư viện CUDA, không phải cài thêm.
$binUrl = 'https://github.com/ggml-org/whisper.cpp/releases/download/b5130/whisper-cublas-12.4.0-bin-x64.zip'
$binSha = 'af520ddd034d985b55dfeea3e465ed93653ba2aee1a55e865033edc548c272a7'
$modelUrl = 'https://huggingface.co/ggerganov/whisper.cpp/resolve/5359861c739e955e79d9a303bcbc70fb988958b1/ggml-large-v3-turbo-q5_0.bin'
$modelSha = '394221709cd5ad1f40c46e6031ca61bce88931e6e088c188294c6d5a55ffa7e2'
$port = 8178

function Download($url, $file, $sha) {
    if ((Test-Path $file) -and (Get-FileHash $file -Algorithm SHA256).Hash -eq $sha) {
        Write-Host "Already downloaded: $(Split-Path $file -Leaf)"
        return
    }
    # curl.exe nhanh hơn nhiều so với Invoke-WebRequest cho file lớn, và hiện thanh
    # tiến độ để không trông như bị treo.
    & curl.exe -L --fail --progress-bar -o $file $url
    if ($LASTEXITCODE -ne 0) { throw "Could not download $url" }
    if ((Get-FileHash $file -Algorithm SHA256).Hash -ne $sha) {
        Remove-Item $file -Force
        throw "The download of $(Split-Path $file -Leaf) is damaged. Run this again."
    }
}

# Gửi đoạn thử (tiếng Việt) cho Whisper; trả về chữ, hoặc $null nếu không được.
function TryTranscribe($seconds) {
    $test = Join-Path $PSScriptRoot 'speech-test.wav'
    $out = Join-Path $env:TEMP 'embrace-speech-test.json'
    for ($i = 0; $i -lt $seconds; $i += 3) {
        try { Invoke-WebRequest "http://127.0.0.1:$port/" -UseBasicParsing -TimeoutSec 3 | Out-Null; break }
        catch { Start-Sleep -Seconds 3 }
    }
    & curl.exe -s -S --max-time 120 -o $out -F "file=@$test" -F 'language=vi' -F 'response_format=json' "http://127.0.0.1:$port/inference"
    if ($LASTEXITCODE -ne 0 -or -not (Test-Path $out)) { return $null }
    $reply = [IO.File]::ReadAllText($out, [Text.Encoding]::UTF8) | ConvertFrom-Json
    Remove-Item $out -Force
    if ([string]::IsNullOrWhiteSpace($reply.text)) { return $null }
    return $reply.text.Trim()
}

function StartServer($useGpu) {
    $taskName = 'EmbraceAI speech server'
    Stop-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue
    Get-Process whisper-server -ErrorAction SilentlyContinue | Stop-Process -Force
    Start-Sleep -Seconds 1
    # Không có GPU thì Whisper dùng một nửa số nhân CPU, chừa phần còn lại cho máy.
    $threads = [Math]::Max(2, [int]([Environment]::ProcessorCount / 2))
    $arguments = "-m `"$model`" --host 127.0.0.1 --port $port -t $threads"
    if (-not $useGpu) { $arguments += ' -ng' }
    $action = New-ScheduledTaskAction -Execute $server -Argument $arguments -WorkingDirectory (Split-Path $server)
    $trigger = New-ScheduledTaskTrigger -AtStartup
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -ExecutionTimeLimit ([TimeSpan]::Zero) -RestartCount 999 -RestartInterval (New-TimeSpan -Minutes 1)
    Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Settings $settings -User 'SYSTEM' -RunLevel Highest | Out-Null
    Start-ScheduledTask -TaskName $taskName
}

try {
    $dir = 'C:\ProgramData\EmbraceAI'
    $speechDir = Join-Path $dir 'whisper'
    if (-not (Test-Path (Join-Path $dir 'model-worker.ps1'))) {
        throw 'The model worker is not installed yet: run 2-CONNECT-TO-SUPABASE.bat first.'
    }
    New-Item -ItemType Directory -Force -Path $speechDir | Out-Null

    Step '1/4 Download whisper.cpp (about 675 MB)'
    $zip = Join-Path $speechDir 'whisper-bin.zip'
    Download $binUrl $zip $binSha
    $binDir = Join-Path $speechDir 'bin'
    Get-Process whisper-server -ErrorAction SilentlyContinue | Stop-Process -Force
    if (Test-Path $binDir) { Remove-Item $binDir -Recurse -Force }
    Expand-Archive $zip -DestinationPath $binDir -Force
    $server = (Get-ChildItem $binDir -Recurse -Filter 'whisper-server.exe' | Select-Object -First 1).FullName
    if (-not $server) { throw 'whisper-server.exe is missing from the download.' }

    Step '2/4 Download the Whisper large-v3-turbo model (about 575 MB)'
    $model = Join-Path $speechDir 'ggml-large-v3-turbo-q5_0.bin'
    Download $modelUrl $model $modelSha

    Step '3/4 Start Whisper and test it with a Vietnamese sentence'
    StartServer $true
    $text = TryTranscribe 60
    $mode = 'GPU'
    if (-not $text) {
        # Card đồ hoạ quá mới cho bản CUDA này, hoặc GPU hết bộ nhớ vì model chat
        # đang chiếm: chạy bằng CPU, chậm hơn nhưng vẫn dùng được.
        Write-Warning 'Whisper did not work on the GPU. Trying the CPU instead.'
        StartServer $false
        $text = TryTranscribe 60
        $mode = 'CPU'
    }
    if (-not $text) {
        throw 'Whisper did not transcribe the test sentence.'
    }
    Write-Host "Whisper heard ($mode): $text"
    try { nvidia-smi --query-gpu=memory.used,memory.total --format=csv,noheader } catch {}

    Step '4/4 Update the model worker so it also takes speech'
    Copy-Item (Join-Path $PSScriptRoot 'model-worker.ps1') $dir -Force
    $workerTask = 'EmbraceAI model worker'
    Stop-ScheduledTask -TaskName $workerTask -ErrorAction SilentlyContinue
    Get-CimInstance Win32_Process -Filter "Name = 'powershell.exe'" |
        Where-Object { $_.CommandLine -like '*model-worker.ps1*' } |
        ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
    Start-ScheduledTask -TaskName $workerTask
    $log = Join-Path $dir 'worker-log.txt'
    $on = $false
    for ($i = 0; $i -lt 10 -and -not $on; $i++) {
        Start-Sleep -Seconds 2
        $on = [bool](Get-Content $log -Tail 5 -ErrorAction SilentlyContinue | Select-String 'speech to text on')
    }
    if (-not $on) {
        Get-Content $log -Tail 10 -ErrorAction SilentlyContinue | Write-Host
        throw 'The worker restarted but does not see Whisper yet.'
    }
    Write-Host "`nDONE. Voice typing in the app now uses Whisper on this PC ($mode)." -ForegroundColor Green
}
catch {
    Write-Host "`nFAILED: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host 'Send speech-setup-log.txt (next to this script) to Claude.'
}
finally {
    Stop-Transcript | Out-Null
    Read-Host 'Press Enter to close'
}
