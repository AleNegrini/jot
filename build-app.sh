#!/bin/bash
# Build Jot and package it into a double-clickable Jot.app bundle.
#
# Usage: ./build-app.sh
# Output: ./Jot.app  (also copies to /Applications if --install is passed)
set -euo pipefail

cd "$(dirname "$0")"

APP_NAME="Jot"
BUNDLE_ID="ch.anegrini.Jot"
CONFIG="release"

echo "==> Building ($CONFIG)…"
swift build -c "$CONFIG"

BIN_PATH="$(swift build -c "$CONFIG" --show-bin-path)"
APP_DIR="./${APP_NAME}.app"
MACOS_DIR="${APP_DIR}/Contents/MacOS"
RES_DIR="${APP_DIR}/Contents/Resources"

echo "==> Assembling ${APP_DIR}…"
rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR" "$RES_DIR"

cp "${BIN_PATH}/${APP_NAME}" "${MACOS_DIR}/${APP_NAME}"

# App icon: regenerate the .icns if missing, then copy it into Resources.
if [[ ! -f "AppIcon.icns" ]]; then
    echo "==> Generating app icon…"
    swift make-icon.swift >/dev/null
    iconutil -c icns AppIcon.iconset -o AppIcon.icns
fi
cp "AppIcon.icns" "${RES_DIR}/AppIcon.icns"

cat > "${APP_DIR}/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>${APP_NAME}</string>
    <key>CFBundleDisplayName</key>
    <string>${APP_NAME}</string>
    <key>CFBundleIdentifier</key>
    <string>${BUNDLE_ID}</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleExecutable</key>
    <string>${APP_NAME}</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
PLIST

# Ad-hoc sign so macOS keeps the Accessibility grant stable across rebuilds
# and the app can launch without a developer certificate.
echo "==> Ad-hoc signing…"
codesign --force --deep --sign - "$APP_DIR"

echo "==> Done: ${APP_DIR}"

if [[ "${1:-}" == "--install" ]]; then
    echo "==> Installing to /Applications…"
    rm -rf "/Applications/${APP_NAME}.app"
    cp -R "$APP_DIR" "/Applications/${APP_NAME}.app"
    echo "==> Installed /Applications/${APP_NAME}.app"
fi
