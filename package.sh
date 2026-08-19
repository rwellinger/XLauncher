#!/bin/bash
set -e

APP_NAME="XLauncher"
SOURCE_NAME="XPlaneLauncher"
BUILD_DIR=".build/release"
APP_BUNDLE="${APP_NAME}.app"
ICON_SOURCE="XLauncherIcon.png"
ICON_FILE="${APP_NAME}.icns"
SKIP_BUILD=false

for arg in "$@"; do
    case $arg in
        --skip-build)
            SKIP_BUILD=true
            ;;
    esac
done

if [ "$SKIP_BUILD" = false ]; then
    echo "Building Release configuration..."
    swift build -c release
fi

echo "Creating App Bundle structure..."
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

echo "Creating Info.plist..."
cat <<EOF > "$APP_BUNDLE/Contents/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>$APP_NAME</string>
    <key>CFBundleIdentifier</key>
    <string>com.jcorbier.XPlaneLauncher</string>
    <key>CFBundleName</key>
    <string>$APP_NAME</string>
    <key>CFBundleShortVersionString</key>
    <string>0.0.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
</dict>
</plist>
EOF

if [ -f "$BUILD_DIR/$SOURCE_NAME" ]; then
    echo "Copying binary..."
    cp "$BUILD_DIR/$SOURCE_NAME" "$APP_BUNDLE/Contents/MacOS/$APP_NAME"
fi

if [ ! -f "$ICON_FILE" ] || [ "$ICON_SOURCE" -nt "$ICON_FILE" ]; then
    if [ -f "$ICON_SOURCE" ]; then
        echo "Generating app icon..."
        ./generate_icon.sh
    fi
fi

echo "Copying resources..."
if [ -f "$ICON_FILE" ]; then
    cp "$ICON_FILE" "$APP_BUNDLE/Contents/Resources/AppIcon.icns"
else
    echo "Warning: $ICON_SOURCE not found, building without an app icon."
fi

echo "Signing app..."
codesign -f -s - "$APP_BUNDLE"

# Nudge the icon cache, otherwise Finder and Dock keep showing the generic icon.
touch "$APP_BUNDLE"

echo "Done! $APP_BUNDLE created."
