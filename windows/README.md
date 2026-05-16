# YouTube Downloader — Windows build

A standalone `YouTubeDownloader.exe` that bundles Python, Flask, `yt-dlp.exe`, and `ffmpeg.exe`. Same browser UI as the macOS version.

## Run pre-built (recommended)

Download `YouTubeDownloader.exe` from the [Releases page](../../releases) and double-click it. A console window opens, the server starts, and your default browser pops to `http://127.0.0.1:8768`. Close the console window to quit.

## Build from source

> PyInstaller produces a `.exe` only when run **on Windows**. You can't cross-compile from macOS.

### Prerequisites (one-time)

1. Install [Python 3.11+ for Windows](https://www.python.org/downloads/windows/). During install, check **"Add python.exe to PATH"**.
2. Open **PowerShell** (or `cmd`).

### Build

```powershell
cd windows
.\build.bat
```

This will:
1. Create a virtualenv in `.venv/`
2. `pip install` Flask, yt-dlp, waitress, PyInstaller
3. Download `yt-dlp.exe`, `ffmpeg.exe`, `ffprobe.exe` into `.\bin\` (~150 MB)
4. Run PyInstaller against [`youtube-downloader.spec`](youtube-downloader.spec)

Result: **`dist\YouTubeDownloader.exe`** (~80-100 MB, single file).

### Test in Parallels Desktop

Mount the macOS folder as a Windows drive, then in the Windows VM:

```powershell
cd "Z:\Users\YOU\YTDownloader\windows"
.\build.bat
```

…or copy the `windows\` folder into the VM and build from there.

## What's bundled

| Component | Source | License |
|---|---|---|
| `yt-dlp.exe` | [yt-dlp/yt-dlp Releases](https://github.com/yt-dlp/yt-dlp/releases) | Unlicense (public domain) |
| `ffmpeg.exe`, `ffprobe.exe` | [gyan.dev essentials build](https://www.gyan.dev/ffmpeg/builds/) | GPL-3.0 (essentials build includes libx264) |
| Python runtime + Flask + waitress | bundled via PyInstaller | BSD-3-Clause / MIT |

## Known limitations

- **Not code-signed** — Windows SmartScreen will warn on first launch. Click **More info → Run anyway**. To remove this warning permanently you'd need an Authenticode certificate ($100-300/year from a CA).
- The .exe shows a console window — close it to quit the server. To hide it, change `console=True` to `console=False` in `youtube-downloader.spec` (you lose the log output, but the app still runs in the background).
- Antivirus false positives are common with PyInstaller `--onefile` builds. If a user reports their AV blocks it, the fix is usually to whitelist the .exe or build with `--onedir` instead (gives a folder of files instead of one large .exe).

## File layout

```
windows/
├── app.py                       Cross-platform Flask backend
├── templates/index.html         Browser UI (dark theme, dynamic quality picker)
├── youtube-downloader.spec      PyInstaller config (onefile, embedded binaries)
├── requirements.txt             Python deps
├── fetch-binaries.ps1           Downloads yt-dlp.exe + ffmpeg.exe into bin\
├── build.bat                    One-line build: venv → install → fetch → pyinstaller
└── README.md                    This file
```
