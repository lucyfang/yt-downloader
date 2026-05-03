# YT Downloader

A clean macOS desktop app to download YouTube videos. A minimal wrapper around yt-dlp with a native Swift UI — no Python, no Homebrew, no setup.

Landing page: https://ytdownloader-minimal.vercel.app/

![YT Downloader screenshot](assets/screenshot.png)

## Features

- Save as MP4 (H.264 or H.265) or MP3 audio
- yt-dlp and ffmpeg bundled — nothing to install
- macOS 13+

## Project structure

```
ytdownloader/
├── app/
│   ├── YTDownloader.swift   ← entire app in one file
│   ├── AppIcon.icns
│   └── bin/
│       ├── yt-dlp           ← bundled (not committed, download separately)
│       └── ffmpeg           ← bundled universal binary (not committed)
└── web/
    ├── index.html           ← landing page (deployed to Vercel)
    ├── favicon.png / .ico
    ├── install.sh
    └── vercel.json
```

## Build from source

Requires Xcode Command Line Tools (`xcode-select --install`).

```bash
cd app

# Download yt-dlp and ffmpeg into bin/ first
mkdir -p bin
curl -L https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp_macos -o bin/yt-dlp
chmod +x bin/yt-dlp
# (place a universal ffmpeg binary at bin/ffmpeg)

# Compile universal binary
swiftc YTDownloader.swift -target arm64-apple-macos13.0 -framework Cocoa -framework WebKit -o YTDownloader_arm64
swiftc YTDownloader.swift -target x86_64-apple-macos13.0 -framework Cocoa -framework WebKit -o YTDownloader_x86_64
lipo -create -output YTDownloader YTDownloader_arm64 YTDownloader_x86_64
rm YTDownloader_arm64 YTDownloader_x86_64

# Install
rm -rf /Applications/YTDownloader.app
mkdir -p /Applications/YTDownloader.app/Contents/MacOS \
         /Applications/YTDownloader.app/Contents/Resources/bin
cp YTDownloader         /Applications/YTDownloader.app/Contents/MacOS/YTDownloader
cp AppIcon.icns         /Applications/YTDownloader.app/Contents/Resources/AppIcon.icns
cp bin/yt-dlp           /Applications/YTDownloader.app/Contents/Resources/bin/yt-dlp
cp bin/ffmpeg           /Applications/YTDownloader.app/Contents/Resources/bin/ffmpeg
chmod +x /Applications/YTDownloader.app/Contents/Resources/bin/yt-dlp \
         /Applications/YTDownloader.app/Contents/Resources/bin/ffmpeg

cat > /Applications/YTDownloader.app/Contents/Info.plist << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>CFBundleName</key><string>YTDownloader</string>
  <key>CFBundleExecutable</key><string>YTDownloader</string>
  <key>CFBundleIdentifier</key><string>com.ytdownloader.app</string>
  <key>CFBundleVersion</key><string>1.1</string>
  <key>CFBundleIconFile</key><string>AppIcon</string>
  <key>NSPrincipalClass</key><string>NSApplication</string>
  <key>NSHighResolutionCapable</key><true/>
</dict></plist>
EOF

xattr -cr /Applications/YTDownloader.app
open /Applications/YTDownloader.app
```

## Tech

- Pure Swift — `Cocoa` + `WebKit` (WKWebView)
- JS ↔ Swift bridge via `window.webkit.messageHandlers.bridge.postMessage()`
- yt-dlp and ffmpeg run as subprocesses, stdout streamed live to the UI
- Prefs saved to `~/.ytdownloader_prefs.json`
