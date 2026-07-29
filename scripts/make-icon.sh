#!/usr/bin/env bash
#
# Tạo lại app icon: vẽ PNG 1024 (make-icon.swift) → iconset → Resources/AppIcon.icns
# Chỉ cần chạy lại khi muốn đổi thiết kế icon (sửa trong scripts/make-icon.swift).
#
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

SRC=/tmp/CopyClipPro-icon.png
ISET=/tmp/CopyClipPro.iconset

echo "▶︎ Vẽ PNG gốc"
swift scripts/make-icon.swift

echo "▶︎ Sinh iconset các kích thước"
rm -rf "$ISET"; mkdir -p "$ISET"
for spec in "16:16x16" "32:16x16@2x" "32:32x32" "64:32x32@2x" \
            "128:128x128" "256:128x128@2x" "256:256x256" "512:256x256@2x" \
            "512:512x512" "1024:512x512@2x"; do
  px="${spec%%:*}"; name="${spec##*:}"
  sips -z "$px" "$px" "$SRC" --out "$ISET/icon_${name}.png" >/dev/null 2>&1
done

echo "▶︎ Biên dịch .icns"
mkdir -p Resources
iconutil -c icns "$ISET" -o Resources/AppIcon.icns
echo "✓ Resources/AppIcon.icns ($(du -h Resources/AppIcon.icns | cut -f1))"
echo "  Chạy ./scripts/package.sh release để đóng lại app với icon mới."
