# Chạy trên máy phát triển, trong thư mục D:\EmbraceAI:
#   powershell -ExecutionPolicy Bypass -File tools\model-server\new-key.ps1
#
# Tạo một khoá bí mật mới dùng chung giữa Supabase (Edge Function ai-worker) và
# chương trình lấy câu hỏi trên máy GPU, đặt khoá vào Supabase secrets, rồi
# đóng bộ cài kèm server-key.txt và supabase-url.txt để mang sang máy GPU.
# Chạy lại là đổi khoá: khoá cũ trên máy GPU hết hiệu lực ngay. Chỉ cần đóng
# lại bộ cài (ví dụ khi sửa model-worker.ps1) thì thêm -KeepKey: giữ khoá đang
# dùng, không đụng tới Supabase, máy GPU không bị ngắt.
# Không gửi khoá này qua chat hay email; các file đều nằm trong .gitignore.
param(
    [string]$Model = 'gpt-oss:20b',
    [switch]$KeepKey
)
$ErrorActionPreference = 'Stop'

$root = Join-Path $PSScriptRoot '..\..'
$config = Get-Content (Join-Path $root 'config\supabase.json') -Raw | ConvertFrom-Json
[IO.File]::WriteAllText((Join-Path $PSScriptRoot 'supabase-url.txt'), $config.SUPABASE_URL.TrimEnd('/'))

$keyFile = Join-Path $PSScriptRoot 'server-key.txt'
if ($KeepKey) {
    if (-not (Test-Path $keyFile)) { throw 'server-key.txt is missing: run new-key.ps1 without -KeepKey.' }
    Write-Host "Keeping the key in $keyFile"
} else {
    $bytes = New-Object byte[] 32
    [Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($bytes)
    $key = -join ($bytes | ForEach-Object { $_.ToString('x2') })
    [IO.File]::WriteAllText($keyFile, $key)
    Write-Host "Saved the key to $keyFile"

    Push-Location $root
    try {
        npx supabase secrets set "MODEL_SERVER_KEY=$key" "MODEL_NAME=$Model"
        if ($LASTEXITCODE -ne 0) { throw 'Could not set the Supabase secrets.' }
    } finally {
        Pop-Location
    }
}

$zip = Join-Path $PSScriptRoot 'EmbraceAI-model-server.zip'
$files = 'START-HERE.bat', 'setup-model-server.ps1', '2-CONNECT-TO-SUPABASE.bat', 'setup-worker.ps1',
    'model-worker.ps1', 'README.txt', 'server-key.txt', 'supabase-url.txt' |
    ForEach-Object { Join-Path $PSScriptRoot $_ }
Compress-Archive -Path $files -DestinationPath $zip -Force
Write-Host "Done. Copy $zip to the GPU machine, unzip it there and double-click 2-CONNECT-TO-SUPABASE.bat." -ForegroundColor Green
Write-Host 'The zip now contains the key: keep it private and delete it after use.' -ForegroundColor Yellow
