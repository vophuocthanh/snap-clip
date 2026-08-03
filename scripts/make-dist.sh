#!/usr/bin/env bash
#
# Đóng gói SnapClip để phân phối sang máy Mac khác.
# Tạo universal binary (Apple Silicon + Intel) → .app → .zip và .dmg.
#
# Yêu cầu máy build: macOS + Xcode/Swift. Máy đích: macOS 14+ (không cần Xcode).
#
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="SnapClip"
DIST="$ROOT/dist"
APP_DIR="$DIST/$APP_NAME.app"

cd "$ROOT"

echo "▶︎ Build universal (arm64 + x86_64)…"
swift build -c release --arch arm64 --arch x86_64
BIN="$(swift build -c release --arch arm64 --arch x86_64 --show-bin-path)/$APP_NAME"

echo "▶︎ Dựng $APP_DIR"
rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS" "$APP_DIR/Contents/Resources"
cp "$BIN" "$APP_DIR/Contents/MacOS/$APP_NAME"
cp "$ROOT/Resources/Info.plist" "$APP_DIR/Contents/Info.plist"
[ -f "$ROOT/Resources/AppIcon.icns" ] && cp "$ROOT/Resources/AppIcon.icns" "$APP_DIR/Contents/Resources/AppIcon.icns"

echo "▶︎ Kiến trúc binary:"; lipo -archs "$APP_DIR/Contents/MacOS/$APP_NAME" 2>/dev/null || true

# Ký ad-hoc (đủ để chạy; máy đích vẫn cần gỡ quarantine — xem cuối script).
codesign --force --deep --sign - "$APP_DIR" 2>/dev/null && echo "✓ ký ad-hoc" || echo "⚠︎ bỏ qua codesign"

echo "▶︎ Tạo .zip"
rm -f "$DIST/$APP_NAME.zip"
ditto -c -k --keepParent "$APP_DIR" "$DIST/$APP_NAME.zip"

echo "▶︎ Tạo .dmg"
rm -f "$DIST/$APP_NAME.dmg"
hdiutil create -volname "$APP_NAME" -srcfolder "$APP_DIR" \
    -ov -format UDZO "$DIST/$APP_NAME.dmg" >/dev/null

echo
echo "✓ Xong. File phân phối:"
echo "   $DIST/$APP_NAME.zip"
echo "   $DIST/$APP_NAME.dmg"
echo
echo "── Cách chạy trên máy Mac khác ──"
echo "1. Copy .dmg (hoặc .zip) sang máy đó, mở ra, kéo $APP_NAME.app vào /Applications."
echo "2. Lần đầu bị Gatekeeper chặn (app ký ad-hoc, chưa notarize) → chạy 1 lệnh gỡ chặn:"
echo "     xattr -cr \"/Applications/$APP_NAME.app\""
echo "   rồi mở app bình thường (hoặc chuột phải → Open)."
echo
echo "※ Muốn KHÔNG cần gỡ chặn thủ công: phải ký bằng Developer ID + notarize"
echo "  (cần tài khoản Apple Developer trả phí). Xem docs/RELEASE.md."
