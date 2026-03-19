#!/bin/bash
set -euo pipefail

VERSION="${1:-1.0.0}"
APP_NAME="Holdor"
BUNDLE_ID="app.holdor.Holdor"
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

echo "==> Done! DMG at: $DMG_PATH"
echo "    Size: $(du -h "$DMG_PATH" | cut -f1)"
