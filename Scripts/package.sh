#!/bin/bash
set -euo pipefail
APP=${1:?Pass the Release app bundle path}
ROOT=$(cd "$(dirname "$0")/.." && pwd)
OUT="$ROOT/dist"
STAGE=$(mktemp -d)
trap 'rm -rf "$STAGE"' EXIT
mkdir -p "$OUT" "$STAGE/image"
test -x "$APP/Contents/MacOS/IP Prism"
test -d "$APP/Contents/PlugIns/IPPrismWidget.appex"
plutil -lint "$APP/Contents/Info.plist"
plutil -lint "$APP/Contents/PlugIns/IPPrismWidget.appex/Contents/Info.plist"
if [ "${SIGNED_RELEASE:-false}" = true ]; then
  codesign --verify --deep --strict --verbose=2 "$APP"
  spctl --assess --type execute --verbose=2 "$APP"
else
  codesign --force --sign - "$APP/Contents/PlugIns/IPPrismWidget.appex"
  codesign --force --sign - "$APP"
  codesign --verify --deep --strict "$APP"
fi
ditto "$APP" "$STAGE/image/IP Prism.app"
ln -s /Applications "$STAGE/image/Applications"
cat > "$STAGE/image/Install.txt" <<'TEXT'
IP Prism
Drag IP Prism.app to Applications, then launch it.
The app appears in the menu bar. Add its widget using Edit Widgets.
Development builds are not Apple-notarized. See the release notes for signing status.
TEXT
hdiutil create -volname 'IP Prism' -srcfolder "$STAGE/image" -ov -format UDZO "$OUT/IPPrism.dmg"
if [ "${SIGNED_RELEASE:-false}" = true ]; then
  codesign --sign "$SIGNING_IDENTITY" --timestamp "$OUT/IPPrism.dmg"
  xcrun notarytool submit "$OUT/IPPrism.dmg" --keychain-profile IPPrismNotary --wait
  xcrun stapler staple "$OUT/IPPrism.dmg"
  xcrun stapler validate "$OUT/IPPrism.dmg"
fi
ditto -c -k --sequesterRsrc --keepParent "$APP" "$OUT/IPPrism.zip"
mkdir "$STAGE/extract"
ditto -x -k "$OUT/IPPrism.zip" "$STAGE/extract"
test -x "$STAGE/extract/IP Prism.app/Contents/MacOS/IP Prism"
mkdir "$STAGE/mount"
hdiutil attach "$OUT/IPPrism.dmg" -mountpoint "$STAGE/mount" -nobrowse -readonly
if ! test -L "$STAGE/mount/Applications" || ! test -d "$STAGE/mount/IP Prism.app"; then
  hdiutil detach "$STAGE/mount"; exit 1
fi
hdiutil detach "$STAGE/mount"
(cd "$OUT" && shasum -a 256 IPPrism.dmg IPPrism.zip > SHA256SUMS.txt && shasum -a 256 -c SHA256SUMS.txt)
