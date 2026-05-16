@echo off
REM Build YouTubeDownloader.exe via PyInstaller.
REM Prerequisites: Python 3.11+ installed and on PATH.
setlocal

cd /d "%~dp0"

if not exist .venv (
    echo Creating virtualenv ...
    python -m venv .venv || goto :err
)

call .venv\Scripts\activate.bat
python -m pip install --upgrade pip
python -m pip install -r requirements.txt || goto :err

if not exist bin\yt-dlp.exe (
    echo Fetching bundled binaries ...
    powershell -ExecutionPolicy Bypass -File fetch-binaries.ps1 || goto :err
)

rmdir /s /q build 2>nul
rmdir /s /q dist 2>nul

pyinstaller --clean youtube-downloader.spec || goto :err

echo.
echo ===========================================
echo Built: dist\YouTubeDownloader.exe
echo Size:
dir dist\YouTubeDownloader.exe | findstr "YouTubeDownloader"
echo ===========================================
goto :eof

:err
echo.
echo Build failed.
exit /b 1
