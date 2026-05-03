#!/bin/bash
set -e

DMG_URL="https://github.com/lucyfang/yt-downloader/releases/latest/download/YTDownloader.dmg"
INSTALL_DIR="/Applications"
APP_NAME="YTDownloader.app"
TMP_DMG="/tmp/YTDownloader_install.dmg"

# Remove any existing copy
if [ -d "$INSTALL_DIR/$APP_NAME" ]; then
  echo "Removing existing installation..."
  rm -rf "$INSTALL_DIR/$APP_NAME"
fi

echo "Downloading YT Downloader..."
curl -L --progress-bar "$DMG_URL" -o "$TMP_DMG"

echo "Mounting disk image..."
MOUNT=$(hdiutil attach "$TMP_DMG" -nobrowse | tail -1 | cut -f3- | sed 's/^[[:space:]]*//')
echo "Mounted at: $MOUNT"

echo "Copying app..."
cp -R "$MOUNT/$APP_NAME" "$INSTALL_DIR/$APP_NAME"

echo "Unmounting..."
hdiutil detach "$MOUNT" -quiet

echo "Removing quarantine..."
xattr -cr "$INSTALL_DIR/$APP_NAME"

rm -f "$TMP_DMG"

echo ""
echo "✅ Done! Opening YT Downloader..."
open "$INSTALL_DIR/$APP_NAME"
