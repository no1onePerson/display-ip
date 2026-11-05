#!/bin/bash
set -euo pipefail
APP=${1:?Pass the Release app bundle path}
ROOT=$(cd "$(dirname "$0")/.." && pwd)
OUT="$ROOT/dist"
STAGE=$(mktemp -d)
trap 'rm -rf "$STAGE"' EXIT
mkdir -p "$OUT" "$STAGE/image"
test -x "$APP/Contents/MacOS/IpBan"
test -d "$APP/Contents/PlugIns/IpBanWidget.appex"
plutil -lint "$APP/Contents/Info.plist"
plutil -lint "$APP/Contents/PlugIns/IpBanWidget.appex/Contents/Info.plist"
if [ "${SIGNED_RELEASE:-false}" = true ]; then
  codesign --verify --deep --strict --verbose=2 "$APP"
  spctl --assess --type execute --verbose=2 "$APP"
else
  codesign --force --sign - "$APP/Contents/PlugIns/IpBanWidget.appex"
  codesign --force --sign - "$APP"
  codesign --verify --deep --strict "$APP"
fi
ditto "$APP" "$STAGE/image/IpBan.app"
ln -s /Applications "$STAGE/image/Applications"
cat > "$STAGE/image/Install.txt" <<'TEXT'
IpBan
Drag IpBan.app to Applications, then launch it.
The app appears in the menu bar. Add its widget using Edit Widgets.
Development builds are not Apple-notarized. See the release notes for signing status.
TEXT
hdiutil create -volname 'IpBan' -srcfolder "$STAGE/image" -ov -format UDZO "$OUT/IpBan.dmg"
if [ "${SIGNED_RELEASE:-false}" = true ]; then
  codesign --sign "$SIGNING_IDENTITY" --timestamp "$OUT/IpBan.dmg"
  xcrun notarytool submit "$OUT/IpBan.dmg" --keychain-profile IpBanNotary --wait
  xcrun stapler staple "$OUT/IpBan.dmg"
  xcrun stapler validate "$OUT/IpBan.dmg"
fi
ditto -c -k --sequesterRsrc --keepParent "$APP" "$OUT/IpBan.zip"
mkdir "$STAGE/extract"
ditto -x -k "$OUT/IpBan.zip" "$STAGE/extract"
test -x "$STAGE/extract/IpBan.app/Contents/MacOS/IpBan"
mkdir "$STAGE/mount"
hdiutil attach "$OUT/IpBan.dmg" -mountpoint "$STAGE/mount" -nobrowse -readonly
if ! test -L "$STAGE/mount/Applications" || ! test -d "$STAGE/mount/IpBan.app"; then
  hdiutil detach "$STAGE/mount"; exit 1
fi
hdiutil detach "$STAGE/mount"
(cd "$OUT" && shasum -a 256 IpBan.dmg IpBan.zip > SHA256SUMS.txt && shasum -a 256 -c SHA256SUMS.txt)
