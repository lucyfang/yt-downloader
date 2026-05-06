#!/bin/bash
set -e

echo ""
echo "  YT Downloader — build from source installer"
echo "  ─────────────────────────────────────────────"
echo ""

# ── 1. Xcode Command Line Tools ──────────────────────────────────────────────
if ! xcode-select -p &>/dev/null; then
  echo "⚠️  Xcode Command Line Tools not found."
  echo "    A dialog will appear — click Install, then re-run this script."
  xcode-select --install
  exit 1
fi
echo "✓ Xcode Command Line Tools"

# ── 2. Temp build directory ───────────────────────────────────────────────────
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/bin"

# ── 3. Download source from GitHub ───────────────────────────────────────────
echo "↓ Downloading source..."
curl -fsSL https://raw.githubusercontent.com/lucyfang/yt-downloader/main/app/YTDownloader.swift \
  -o "$TMP/YTDownloader.swift" || { echo "✗ Failed to download source. Check your internet connection."; exit 1; }
curl -fsSL https://raw.githubusercontent.com/lucyfang/yt-downloader/main/app/AppIcon.icns \
  -o "$TMP/AppIcon.icns" || { echo "✗ Failed to download AppIcon."; exit 1; }
curl -fsSL https://ytdownloader-minimal.vercel.app/favicon.png \
  -o "$TMP/icon.png" || { echo "✗ Failed to download icon."; exit 1; }
echo "✓ Source downloaded"

# ── 4. yt-dlp ────────────────────────────────────────────────────────────────
if command -v yt-dlp &>/dev/null; then
  echo "✓ yt-dlp found ($(which yt-dlp))"
  cp "$(which yt-dlp)" "$TMP/bin/yt-dlp"
else
  echo "↓ Downloading yt-dlp..."
  curl -fsSL https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp_macos \
    -o "$TMP/bin/yt-dlp" || { echo "✗ Failed to download yt-dlp."; exit 1; }
  echo "✓ yt-dlp downloaded"
fi
chmod +x "$TMP/bin/yt-dlp"

# ── 5. ffmpeg ─────────────────────────────────────────────────────────────────
FFMPEG=""
for loc in /opt/homebrew/bin/ffmpeg /usr/local/bin/ffmpeg /usr/bin/ffmpeg; do
  if [ -x "$loc" ]; then
    FFMPEG="$loc"
    break
  fi
done

if [ -n "$FFMPEG" ]; then
  echo "✓ ffmpeg found ($FFMPEG)"
  cp "$FFMPEG" "$TMP/bin/ffmpeg"
elif command -v brew &>/dev/null; then
  echo "↓ Installing ffmpeg via Homebrew (this may take a few minutes)..."
  brew install ffmpeg
  cp "$(which ffmpeg)" "$TMP/bin/ffmpeg"
  echo "✓ ffmpeg installed"
else
  echo ""
  echo "✗ ffmpeg not found and Homebrew is not installed."
  echo "  Install Homebrew: /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
  echo "  Then run: brew install ffmpeg"
  echo "  Then re-run this script."
  exit 1
fi
chmod +x "$TMP/bin/ffmpeg"

# ── 6. Compile ────────────────────────────────────────────────────────────────
echo "⚙️  Compiling (this takes ~30 seconds)..."
COMPILE_LOG="$TMP/compile.log"
swiftc "$TMP/YTDownloader.swift" \
  -target arm64-apple-macos13.0 \
  -framework Cocoa -framework WebKit \
  -o "$TMP/YTDownloader_arm64" 2>"$COMPILE_LOG" \
  || { cat "$COMPILE_LOG"; echo "✗ Compilation failed. Make sure Xcode Command Line Tools are up to date: xcode-select --install"; exit 1; }
swiftc "$TMP/YTDownloader.swift" \
  -target x86_64-apple-macos13.0 \
  -framework Cocoa -framework WebKit \
  -o "$TMP/YTDownloader_x86_64" 2>>"$COMPILE_LOG" \
  || { cat "$COMPILE_LOG"; echo "✗ Compilation failed."; exit 1; }
lipo -create -output "$TMP/YTDownloader" "$TMP/YTDownloader_arm64" "$TMP/YTDownloader_x86_64" \
  || { echo "✗ Failed to create universal binary."; exit 1; }
echo "✓ Compiled"

# ── 7. Install ────────────────────────────────────────────────────────────────
echo "📦 Installing to /Applications (you may be prompted for your password)..."
sudo rm -rf /Applications/YTDownloader.app
sudo mkdir -p /Applications/YTDownloader.app/Contents/MacOS \
              /Applications/YTDownloader.app/Contents/Resources/bin

sudo cp "$TMP/YTDownloader"  /Applications/YTDownloader.app/Contents/MacOS/YTDownloader
sudo cp "$TMP/AppIcon.icns"  /Applications/YTDownloader.app/Contents/Resources/AppIcon.icns
sudo cp "$TMP/icon.png"      /Applications/YTDownloader.app/Contents/Resources/icon.png
sudo cp "$TMP/bin/yt-dlp"    /Applications/YTDownloader.app/Contents/Resources/bin/yt-dlp
sudo cp "$TMP/bin/ffmpeg"    /Applications/YTDownloader.app/Contents/Resources/bin/ffmpeg
sudo chmod +x /Applications/YTDownloader.app/Contents/Resources/bin/yt-dlp \
              /Applications/YTDownloader.app/Contents/Resources/bin/ffmpeg

# Write Info.plist via temp file so sudo cp works cleanly
cat > "$TMP/Info.plist" << 'EOF'
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
sudo cp "$TMP/Info.plist" /Applications/YTDownloader.app/Contents/Info.plist

sudo xattr -cr /Applications/YTDownloader.app
echo "✓ Installed"
echo ""
echo "✅ Done! Opening YT Downloader..."
echo ""
open /Applications/YTDownloader.app
