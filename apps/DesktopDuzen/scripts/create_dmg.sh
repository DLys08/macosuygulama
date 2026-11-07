#!/bin/bash
# Packages an already-built DesktopDuzen.app into a compressed, signed DMG and verifies it.
# Run scripts/build_app.sh first (or pass --build).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
APP="$PROJECT_DIR/DesktopDuzen.app"
VERSION="$(/usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' "$APP/Contents/Info.plist" 2>/dev/null || echo 1.0)"
DMG_PATH="$PROJECT_DIR/DesktopDuzen-$VERSION.dmg"
STAGE="$(mktemp -d /tmp/DesktopDuzen_dmg.XXXXXX)"
IDENTITY="${DD_SIGN_IDENTITY:-$(security find-identity -v -p codesigning 2>/dev/null | grep -m1 'Developer ID Application' | sed -E 's/.*"(.*)"/\1/' || true)}"

if [ "${1:-}" = "--build" ] || [ ! -d "$APP" ]; then
    "$SCRIPT_DIR/build_app.sh"
fi
codesign --verify --strict "$APP"

echo "==> Staging"
ditto "$APP" "$STAGE/DesktopDüzen.app"
ln -s /Applications "$STAGE/Applications"
cat > "$STAGE/Read Me.txt" <<'EOF'
DesktopDüzen
Drag DesktopDüzen onto the Applications folder, then open it from Applications.
Zones live on your Desktop; zone folders are kept in ~/Desktop/Zones.
Your layout is stored in ~/Library/Application Support/DesktopDuzen/state.json.
EOF

echo "==> Creating $DMG_PATH"
rm -f "$DMG_PATH"
hdiutil create -volname "DesktopDüzen" -srcfolder "$STAGE" -ov -format UDZO -fs HFS+ "$DMG_PATH" >/dev/null
rm -rf "$STAGE"

if [ -n "$IDENTITY" ]; then
    codesign --force --timestamp --sign "$IDENTITY" "$DMG_PATH" || codesign --force --sign "$IDENTITY" "$DMG_PATH"
fi

echo "==> Verifying"
hdiutil verify "$DMG_PATH" >/dev/null && echo "  [OK] checksum"
MOUNT="$(mktemp -d /tmp/DesktopDuzen_mount.XXXXXX)"
hdiutil attach "$DMG_PATH" -mountpoint "$MOUNT" -nobrowse -readonly -quiet
trap 'hdiutil detach "$MOUNT" -quiet || true' EXIT
[ -d "$MOUNT/DesktopDüzen.app" ] && echo "  [OK] app bundle present"
[ -L "$MOUNT/Applications" ] && echo "  [OK] Applications link present"
codesign --verify --strict "$MOUNT/DesktopDüzen.app" && echo "  [OK] app signature valid inside DMG"
echo "==> $DMG_PATH"
ls -lh "$DMG_PATH"
