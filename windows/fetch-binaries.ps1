# Fetch the Windows binaries (yt-dlp.exe, ffmpeg.exe, ffprobe.exe, deno.exe) into .\bin\
# Run from PowerShell:  .\fetch-binaries.ps1
$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$bin = Join-Path $root "bin"
New-Item -ItemType Directory -Force -Path $bin | Out-Null

Write-Host ">> Downloading yt-dlp.exe ..."
Invoke-WebRequest -Uri "https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp.exe" `
  -OutFile (Join-Path $bin "yt-dlp.exe")

Write-Host ">> Downloading ffmpeg (gyan.dev essentials build) ..."
$tmp = New-Item -ItemType Directory -Path ([System.IO.Path]::GetTempPath()) -Name ("ffmpeg_dl_" + [Guid]::NewGuid())
$zip = Join-Path $tmp.FullName "ffmpeg.zip"
Invoke-WebRequest -Uri "https://www.gyan.dev/ffmpeg/builds/ffmpeg-release-essentials.zip" -OutFile $zip
Expand-Archive -Path $zip -DestinationPath $tmp.FullName -Force
$extracted = Get-ChildItem -Path $tmp.FullName -Directory | Select-Object -First 1
Copy-Item -Path (Join-Path $extracted.FullName "bin\ffmpeg.exe") -Destination (Join-Path $bin "ffmpeg.exe") -Force
Copy-Item -Path (Join-Path $extracted.FullName "bin\ffprobe.exe") -Destination (Join-Path $bin "ffprobe.exe") -Force
Remove-Item -Recurse -Force $tmp.FullName

Write-Host ">> Downloading deno (JS runtime for YouTube anti-bot challenges) ..."
$denoTmp = New-Item -ItemType Directory -Path ([System.IO.Path]::GetTempPath()) -Name ("deno_dl_" + [Guid]::NewGuid())
$denoZip = Join-Path $denoTmp.FullName "deno.zip"
Invoke-WebRequest -Uri "https://github.com/denoland/deno/releases/latest/download/deno-x86_64-pc-windows-msvc.zip" -OutFile $denoZip
Expand-Archive -Path $denoZip -DestinationPath $denoTmp.FullName -Force
Copy-Item -Path (Join-Path $denoTmp.FullName "deno.exe") -Destination (Join-Path $bin "deno.exe") -Force
Remove-Item -Recurse -Force $denoTmp.FullName

Write-Host ""
Write-Host "Done. Binaries:"
Get-ChildItem $bin | Format-Table Name, Length
