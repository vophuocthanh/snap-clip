# Phân phối & Phát hành CopyClipPro

> **Lưu ý:** CopyClipPro là app **macOS native** (Swift/AppKit/SwiftUI). Không thể
> đóng gói bằng Docker hay chạy trên Linux/Windows. Máy đích bắt buộc là **macOS 14+**.

## 1. Đóng gói để đưa sang máy Mac khác (nhanh)

```bash
./scripts/make-dist.sh
```

Sinh ra trong `dist/`:
- `CopyClipPro.app` — universal binary (Apple Silicon **và** Intel).
- `CopyClipPro.zip` — gọn, dễ gửi.
- `CopyClipPro.dmg` — ảnh đĩa, kéo-thả cài đặt.

### Chạy trên máy Mac khác
1. Copy `.dmg` (hoặc `.zip`) sang máy đó → mở → kéo `CopyClipPro.app` vào `/Applications`.
2. App đang ký **ad-hoc** (chưa notarize) nên Gatekeeper chặn lần đầu. Gỡ chặn:
   ```bash
   xattr -cr "/Applications/CopyClipPro.app"
   ```
   Hoặc: chuột phải vào app → **Open** → **Open** lại lần nữa.

## 2. Phát hành "sạch" (không cần gỡ chặn thủ công)

Để người dùng mở app bình thường không bị cảnh báo, cần **Developer ID + notarization**
(yêu cầu tài khoản **Apple Developer** trả phí ~99 USD/năm):

```bash
# 1. Ký bằng Developer ID Application
codesign --force --deep --options runtime \
  --sign "Developer ID Application: TÊN CỦA BẠN (TEAMID)" dist/CopyClipPro.app

# 2. Nén và gửi notarize
ditto -c -k --keepParent dist/CopyClipPro.app dist/CopyClipPro-notarize.zip
xcrun notarytool submit dist/CopyClipPro-notarize.zip \
  --apple-id "you@example.com" --team-id "TEAMID" --password "APP_SPECIFIC_PASSWORD" \
  --wait

# 3. Đóng dấu (staple) kết quả vào app
xcrun stapler staple dist/CopyClipPro.app
```

Sau đó đóng lại thành `.dmg`/`.zip` để phân phối — máy đích mở thẳng, không cảnh báo.

## 3. Quyền cần cấp trên máy đích

- **Accessibility** (tuỳ chọn): để bật tự động dán (⌘V). System Settings → Privacy &
  Security → Accessibility. Không cấp thì nội dung vẫn nằm trong clipboard để tự dán.
- Global hotkey (Carbon) **không cần** quyền gì.

## 4. Hướng phát triển tiếp cho release

- **Auto-update**: tích hợp Sparkle (feed appcast) — xem docs/ROADMAP.md, Sprint 6.
- **CI**: dựng universal build + notarize tự động (GitHub Actions trên runner macOS).
- **Crash reporting / logging** trước khi phát hành rộng.
