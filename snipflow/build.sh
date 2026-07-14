#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

echo "=== Building SnipFlow ==="

APP_NAME="SnipFlow"
APP_BUNDLE="${APP_NAME}.app"
CONTENTS_DIR="${APP_BUNDLE}/Contents"
MACOS_DIR="${CONTENTS_DIR}/MacOS"
RESOURCES_DIR="${CONTENTS_DIR}/Resources"

# 1. Clean old builds
echo "Cleaning old build files..."
rm -rf "${APP_BUNDLE}"
rm -f "${APP_NAME}"

# 2. Compile Swift files
echo "Compiling Swift source files..."
swiftc -parse-as-library \
       -sdk $(xcrun --show-sdk-path) \
       -target arm64-apple-macosx14.0 \
       OCRManager.swift \
       StickerWindow.swift \
       CaptureManager.swift \
       GlobalHotkey.swift \
       FloatingHUD.swift \
       SettingsView.swift \
       AppDelegate.swift \
       AppMain.swift \
       -o "${APP_NAME}"

# 3. Create app bundle structure
echo "Creating application bundle directories..."
mkdir -p "${MACOS_DIR}"
mkdir -p "${RESOURCES_DIR}"

# 4. Move binary to bundle
echo "Installing binary..."
mv "${APP_NAME}" "${MACOS_DIR}/"

# 4b. Generate and install AppIcon
echo "Generating and installing AppIcon..."
swift ../generate_icons.swift snipflow .
iconutil -c icns AppIcon.iconset
mv AppIcon.icns "${RESOURCES_DIR}/"
rm -rf AppIcon.iconset

# 5. Create Info.plist configuration
echo "Generating Info.plist..."
cat <<EOF > "${CONTENTS_DIR}/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>${APP_NAME}</string>
    <key>CFBundleIdentifier</key>
    <string>com.dawid.SnipFlow</string>
    <key>CFBundleName</key>
    <string>${APP_NAME}</string>
    <key>CFBundleDisplayName</key>
    <string>${APP_NAME}</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
</dict>
</plist>
EOF

echo "=== Build Completed Successfully ==="
echo "You can run the app using: open ${APP_BUNDLE}"
