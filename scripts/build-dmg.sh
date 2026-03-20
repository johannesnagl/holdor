#!/bin/bash
set -euo pipefail

VERSION="${1:-1.0.0}"
APP_NAME="Holdor"
BUNDLE_ID="app.holdor.Holdor"
SIGN_IDENTITY="${SIGN_IDENTITY:-}"
NOTARIZE_PROFILE="${NOTARIZE_PROFILE:-}"
BUILD_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_DIR="$BUILD_DIR/dist/$APP_NAME.app"
DMG_NAME="Holdor-${VERSION}-arm64.dmg"
DMG_PATH="$BUILD_DIR/dist/$DMG_NAME"

echo "==> Building $APP_NAME v$VERSION..."
cd "$BUILD_DIR/app"
swift build -c release

echo "==> Creating app bundle..."
rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"

# Copy binary
cp .build/release/Holdor "$APP_DIR/Contents/MacOS/Holdor"

# Copy app icon
if [ -f "Sources/Holdor/Resources/AppIcon.icns" ]; then
    cp Sources/Holdor/Resources/AppIcon.icns "$APP_DIR/Contents/Resources/AppIcon.icns"
fi

# Create Info.plist
cat > "$APP_DIR/Contents/Info.plist" << PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>$APP_NAME</string>
    <key>CFBundleDisplayName</key>
    <string>$APP_NAME</string>
    <key>CFBundleIdentifier</key>
    <string>$BUNDLE_ID</string>
    <key>CFBundleVersion</key>
    <string>$VERSION</string>
    <key>CFBundleShortVersionString</key>
    <string>$VERSION</string>
    <key>CFBundleExecutable</key>
    <string>Holdor</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
PLIST

if [ -n "$SIGN_IDENTITY" ]; then
    echo "==> Signing app bundle..."
    codesign --force --options runtime --sign "$SIGN_IDENTITY" \
        --identifier "$BUNDLE_ID" \
        "$APP_DIR/Contents/MacOS/Holdor"
    codesign --force --options runtime --sign "$SIGN_IDENTITY" \
        --identifier "$BUNDLE_ID" \
        "$APP_DIR"

    echo "==> Verifying signature..."
    codesign --verify --deep --strict "$APP_DIR"
else
    echo "==> Skipping code signing (set SIGN_IDENTITY to enable)"
fi

echo "==> Creating DMG..."
rm -f "$DMG_PATH"
mkdir -p "$BUILD_DIR/dist"

# Create a temporary directory for DMG contents
DMG_STAGING="$BUILD_DIR/dist/dmg-staging"
rm -rf "$DMG_STAGING"
mkdir -p "$DMG_STAGING"
cp -R "$APP_DIR" "$DMG_STAGING/"
ln -s /Applications "$DMG_STAGING/Applications"

hdiutil create -volname "$APP_NAME" \
    -srcfolder "$DMG_STAGING" \
    -ov -format UDZO \
    "$DMG_PATH"

rm -rf "$DMG_STAGING"

if [ -n "$SIGN_IDENTITY" ]; then
    echo "==> Signing DMG..."
    codesign --force --sign "$SIGN_IDENTITY" "$DMG_PATH"

    if [ -n "$NOTARIZE_PROFILE" ]; then
        echo "==> Notarizing DMG (this may take a few minutes)..."
        xcrun notarytool submit "$DMG_PATH" \
            --keychain-profile "$NOTARIZE_PROFILE" \
            --wait

        echo "==> Stapling notarization ticket..."
        xcrun stapler staple "$DMG_PATH"

        echo "==> Verifying notarization..."
        spctl --assess --type execute --verbose "$APP_DIR"
    else
        echo "==> Skipping notarization (set NOTARIZE_PROFILE to enable)"
    fi
else
    echo "==> Skipping signing and notarization (set SIGN_IDENTITY to enable)"
fi

echo "==> Done! DMG at: $DMG_PATH"
echo "    Size: $(du -h "$DMG_PATH" | cut -f1)"
