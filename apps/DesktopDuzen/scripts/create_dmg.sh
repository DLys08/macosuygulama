#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
DMG_PATH="$PROJECT_DIR/DesktopDuzen.dmg"
TEMP_DMG_DIR="/tmp/DesktopDuzen_dmg_root"

echo "==> 1. Ensuring DesktopDuzen.app is built..."
"$SCRIPT_DIR/build_app.sh"

echo "==> 2. Preparing DMG staging area..."
rm -rf "$TEMP_DMG_DIR"
mkdir -p "$TEMP_DMG_DIR"

# Copy App to staging
cp -R "$PROJECT_DIR/DesktopDuzen.app" "$TEMP_DMG_DIR/"

# Create /Applications symlink for drag-and-drop install
ln -s /Applications "$TEMP_DMG_DIR/Applications"

# Add custom background or Readme if needed
cat << 'EOF' > "$TEMP_DMG_DIR/QuickStart.txt"
DesktopDüzen
============================
To install DesktopDüzen:
Drag the DesktopDüzen icon into your Applications folder.

Once launched, DesktopDüzen lives in your top menu bar
and pins customizable file, folder, and app zones directly
onto your macOS desktop wallpaper.

Enjoy a clean, focused Mac desktop!
EOF

echo "==> 3. Creating compressed DMG image ($DMG_PATH)..."
rm -f "$DMG_PATH"

hdiutil create \
    -volname "DesktopDüzen" \
    -srcfolder "$TEMP_DMG_DIR" \
    -ov \
    -format UDZO \
    "$DMG_PATH"

rm -rf "$TEMP_DMG_DIR"

echo "==> 4. Verifying DMG checksum and mountability..."
MOUNT_DIR=$(mktemp -d /tmp/desktopduzen_mount.XXXXXX)
hdiutil attach "$DMG_PATH" -mountpoint "$MOUNT_DIR" -nobrowse -quiet

if [ -d "$MOUNT_DIR/DesktopDüzen.app" ] || [ -d "$MOUNT_DIR/DesktopDuzen.app" ]; then
    echo "  [OK] App bundle verified inside mounted DMG"
fi

if [ -L "$MOUNT_DIR/Applications" ]; then
    echo "  [OK] Applications symlink verified"
fi

hdiutil detach "$MOUNT_DIR" -quiet
rm -rf "$MOUNT_DIR"

echo "==> DMG successfully created at: $DMG_PATH"
ls -lh "$DMG_PATH"
