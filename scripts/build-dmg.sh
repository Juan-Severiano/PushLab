#!/usr/bin/env bash
set -euo pipefail

PROJECT="${PROJECT:-PushLab.xcodeproj}"
SCHEME="${SCHEME:-PushLab}"
CONFIGURATION="${CONFIGURATION:-Release}"
OUTPUT_DIR="${OUTPUT_DIR:-dist}"
ARCHIVE_PATH="$OUTPUT_DIR/$SCHEME.xcarchive"
DMG_PATH="$OUTPUT_DIR/$SCHEME.dmg"
APP_PATH="$ARCHIVE_PATH/Products/Applications/$SCHEME.app"

: "${DEVELOPMENT_TEAM:?DEVELOPMENT_TEAM is required}"
: "${SIGNING_IDENTITY:?SIGNING_IDENTITY is required}"
: "${NOTARIZATION_KEY_PATH:?NOTARIZATION_KEY_PATH is required}"
: "${NOTARIZATION_KEY_ID:?NOTARIZATION_KEY_ID is required}"
: "${NOTARIZATION_ISSUER_ID:?NOTARIZATION_ISSUER_ID is required}"

mkdir -p "$OUTPUT_DIR"
rm -rf "$ARCHIVE_PATH" "$DMG_PATH"

xcodebuild archive \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -configuration "$CONFIGURATION" \
  -destination "generic/platform=macOS" \
  -archivePath "$ARCHIVE_PATH" \
  CODE_SIGN_STYLE=Manual \
  DEVELOPMENT_TEAM="$DEVELOPMENT_TEAM" \
  CODE_SIGN_IDENTITY="$SIGNING_IDENTITY" \
  CODE_SIGNING_ALLOWED=YES

test -d "$APP_PATH"
codesign --verify --deep --strict --verbose=2 "$APP_PATH"

hdiutil create \
  -volname "$SCHEME" \
  -srcfolder "$APP_PATH" \
  -ov \
  -format UDZO \
  "$DMG_PATH"

codesign --force --sign "$SIGNING_IDENTITY" --timestamp "$DMG_PATH"

xcrun notarytool submit "$DMG_PATH" \
  --key "$NOTARIZATION_KEY_PATH" \
  --key-id "$NOTARIZATION_KEY_ID" \
  --issuer "$NOTARIZATION_ISSUER_ID" \
  --wait

xcrun stapler staple "$DMG_PATH"
spctl --assess --type open --context context:primary-signature -vv "$DMG_PATH"

echo "Created notarized installer: $DMG_PATH"
