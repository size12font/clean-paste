#!/usr/bin/env bash
set -euo pipefail

APP_NAME="CleanPaste"
EXECUTABLE_NAME="CleanPasteMac"
BUNDLE_ID="com.johnnyquach.CleanPasteMac"
MIN_SYSTEM_VERSION="14.0"
VERSION="0.2.0"
IDENTITY="${CLEANPASTE_SIGNING_IDENTITY:-}"
NOTARY_PROFILE="${CLEANPASTE_NOTARY_PROFILE:-CleanPaste}"
LOCAL_ONLY=false

usage() {
  cat <<'EOF'
Usage: ./script/package_dmg.sh [--version VERSION] [--identity IDENTITY] [--notary-profile PROFILE] [--local-only]

Default creates a Developer ID-signed, notarized beta DMG for sharing.
--local-only creates an ad-hoc-signed DMG for this Mac only; do not share it.

Environment alternatives:
  CLEANPASTE_SIGNING_IDENTITY
  CLEANPASTE_NOTARY_PROFILE
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --version) VERSION="$2"; shift 2 ;;
    --identity) IDENTITY="$2"; shift 2 ;;
    --notary-profile) NOTARY_PROFILE="$2"; shift 2 ;;
    --local-only) LOCAL_ONLY=true; shift ;;
    --help|-h) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage >&2; exit 2 ;;
  esac
done

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PACKAGE_DIR="$ROOT_DIR/CleanPaste"
RELEASE_DIR="$ROOT_DIR/dist/release"
APP_BUNDLE="$RELEASE_DIR/$APP_NAME.app"
APP_CONTENTS="$APP_BUNDLE/Contents"
APP_MACOS="$APP_CONTENTS/MacOS"
DMG_STAGING="$RELEASE_DIR/dmg"
DMG_PATH="$RELEASE_DIR/$APP_NAME-$VERSION.dmg"
APP_ZIP="$RELEASE_DIR/$APP_NAME-$VERSION.zip"

if ! "$LOCAL_ONLY"; then
  if [[ -z "$IDENTITY" ]]; then
    IDENTITY="$(security find-identity -v -p codesigning | awk -F '\"' '/Developer ID Application:/ { print $2; exit }')"
  fi
  if [[ -z "$IDENTITY" ]]; then
    echo "No Developer ID Application certificate found. Install one, then rerun." >&2
    echo "For this Mac only, use: ./script/package_dmg.sh --local-only" >&2
    exit 1
  fi
fi

rm -rf "$APP_BUNDLE" "$DMG_STAGING" "$DMG_PATH" "$APP_ZIP"
mkdir -p "$APP_MACOS" "$DMG_STAGING"

swift build --package-path "$PACKAGE_DIR" --configuration release --product "$EXECUTABLE_NAME"
BUILD_BINARY="$(swift build --package-path "$PACKAGE_DIR" --configuration release --show-bin-path)/$EXECUTABLE_NAME"

cp "$BUILD_BINARY" "$APP_MACOS/$EXECUTABLE_NAME"
chmod +x "$APP_MACOS/$EXECUTABLE_NAME"

cat >"$APP_CONTENTS/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "https://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDisplayName</key>
  <string>$APP_NAME</string>
  <key>CFBundleExecutable</key>
  <string>$EXECUTABLE_NAME</string>
  <key>CFBundleIdentifier</key>
  <string>$BUNDLE_ID</string>
  <key>CFBundleName</key>
  <string>$APP_NAME</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>$VERSION</string>
  <key>CFBundleVersion</key>
  <string>$VERSION</string>
  <key>LSMinimumSystemVersion</key>
  <string>$MIN_SYSTEM_VERSION</string>
  <key>LSUIElement</key>
  <true/>
  <key>NSHighResolutionCapable</key>
  <true/>
  <key>NSPrincipalClass</key>
  <string>NSApplication</string>
</dict>
</plist>
PLIST

if "$LOCAL_ONLY"; then
  codesign --force --deep --sign - "$APP_BUNDLE"
else
  codesign --force --deep --options runtime --timestamp --sign "$IDENTITY" "$APP_BUNDLE"
fi
codesign --verify --deep --strict --verbose=2 "$APP_BUNDLE"

if ! "$LOCAL_ONLY"; then
  ditto -c -k --keepParent "$APP_BUNDLE" "$APP_ZIP"
  xcrun notarytool submit "$APP_ZIP" --keychain-profile "$NOTARY_PROFILE" --wait
  xcrun stapler staple "$APP_BUNDLE"
fi

cp -R "$APP_BUNDLE" "$DMG_STAGING/"
ln -s /Applications "$DMG_STAGING/Applications"
hdiutil create -volname "$APP_NAME" -srcfolder "$DMG_STAGING" -format UDZO -ov "$DMG_PATH"
rm -rf "$DMG_STAGING"

if "$LOCAL_ONLY"; then
  codesign --force --sign - "$DMG_PATH"
else
  codesign --force --timestamp --sign "$IDENTITY" "$DMG_PATH"
  xcrun notarytool submit "$DMG_PATH" --keychain-profile "$NOTARY_PROFILE" --wait
  xcrun stapler staple "$DMG_PATH"
  spctl --assess --type open --context context:primary-signature -vv "$DMG_PATH"
fi

echo "Created: $DMG_PATH"
