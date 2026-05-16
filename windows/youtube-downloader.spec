# PyInstaller spec for the YouTube Downloader Windows build.
# Run: pyinstaller youtube-downloader.spec
# Produces dist/YouTubeDownloader.exe (one-file)

from pathlib import Path
ROOT = Path.cwd()

a = Analysis(
    ['app.py'],
    pathex=[str(ROOT)],
    binaries=[],
    datas=[
        # Templates and bundled CLI binaries land at the executable root at runtime.
        ('templates', 'templates'),
        ('bin', 'bin'),
    ],
    hiddenimports=[
        'yt_dlp',
        'yt_dlp.extractor',
        'yt_dlp.utils',
        'waitress',
    ],
    hookspath=[],
    hooksconfig={},
    runtime_hooks=[],
    excludes=['tkinter', 'matplotlib', 'numpy', 'PIL', 'pytest', 'IPython'],
    noarchive=False,
)
pyz = PYZ(a.pure)

exe = EXE(
    pyz,
    a.scripts,
    a.binaries,
    a.datas,
    [],
    name='YouTubeDownloader',
    debug=False,
    bootloader_ignore_signals=False,
    strip=False,
    upx=False,
    runtime_tmpdir=None,
    console=True,        # keep a small console window so users see logs + can close it to quit
    disable_windowed_traceback=False,
    target_arch=None,
    codesign_identity=None,
    entitlements_file=None,
    icon='icon.ico' if Path('icon.ico').exists() else None,
)
