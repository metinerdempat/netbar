#!/usr/bin/env bash
# Bundles NetBar into a double-clickable .app.
# Usage:  ./build-app.sh   →  produces ./NetBar.app
set -euo pipefail
cd "$(dirname "$0")"

echo "Building release..."
swift build -c release

APP="NetBar.app"
BIN=".build/release/NetBar"

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
cp "$BIN" "$APP/Contents/MacOS/NetBar"

cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleName</key>            <string>NetBar</string>
  <key>CFBundleDisplayName</key>     <string>NetBar</string>
  <key>CFBundleIdentifier</key>      <string>com.netbar.app</string>
  <key>CFBundleVersion</key>         <string>1.0</string>
  <key>CFBundleShortVersionString</key> <string>1.0</string>
  <key>CFBundlePackageType</key>     <string>APPL</string>
  <key>CFBundleExecutable</key>      <string>NetBar</string>
  <key>LSMinimumSystemVersion</key>  <string>13.0</string>
  <!-- Menu-bar app: no Dock icon. -->
  <key>LSUIElement</key>            <true/>
</dict>
</plist>
PLIST

# Ad-hoc signature (reduces the Gatekeeper prompt; not sufficient for App Store distribution).
codesign --force --deep --sign - "$APP" >/dev/null 2>&1 || true

echo "Ready:   $(pwd)/$APP"
echo "Open:    open $APP"
echo "Install: cp -R $APP /Applications/"
