#!/usr/bin/env bash
#
# Đóng gói executable từ SwiftPM thành một .app bundle chạy được như menu bar app.
# Dùng cho phát triển & chạy thử cục bộ. Ký/notarize là bước riêng (xem docs/RELEASE.md).
#
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="SnapClip"
CONFIG="${1:-release}"          # release | debug
BUILD_DIR="$ROOT/.build/$CONFIG"
APP_DIR="$ROOT/dist/$APP_NAME.app"

echo "▶︎ Building ($CONFIG)…"
cd "$ROOT"
swift build -c "$CONFIG"

echo "▶︎ Tạo bundle tại $APP_DIR"
rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"

cp "$BUILD_DIR/$APP_NAME" "$APP_DIR/Contents/MacOS/$APP_NAME"
cp "$ROOT/Resources/Info.plist" "$APP_DIR/Contents/Info.plist"
[ -f "$ROOT/Resources/AppIcon.icns" ] && cp "$ROOT/Resources/AppIcon.icns" "$APP_DIR/Contents/Resources/AppIcon.icns"

# Ký ad-hoc để chạy cục bộ (đủ cho dev; phát hành cần Developer ID).
codesign --force --deep --sign - "$APP_DIR" 2>/dev/null || \
    echo "⚠︎ codesign ad-hoc bỏ qua (không bắt buộc khi dev)."

echo "✓ Xong: $APP_DIR"
echo "  Chạy:  open \"$APP_DIR\""
