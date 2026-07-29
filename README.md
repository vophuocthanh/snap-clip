# CopyClipPro

Trình quản lý lịch sử clipboard (Clipboard History) **native cho macOS**, viết bằng **Swift + SwiftUI + AppKit**, lưu trữ bằng **SQLite**. Zero-dependency — chỉ dùng API chính thức của Apple.

> Lấy cảm hứng từ CopyClip, Maccy và Raycast Clipboard History, nhưng có kiến trúc phân lớp riêng, dễ mở rộng và bảo trì. Mục tiêu: chất lượng phát hành thật (Production Ready).

## Tính năng (MVP hiện tại)

- 📋 **Clipboard History** — tự động ghi lại mọi nội dung text được copy
- 🔍 **Tìm kiếm tức thời** (debounce, LIKE + index)
- 📌 **Ghim (Pin)** và ⭐ **Yêu thích (Favorite)** — được bảo vệ khỏi dọn dẹp
- ⌨️ **Global hotkey ⌘⇧V** — mở nhanh từ bất cứ đâu (không cần quyền Accessibility)
- ↕️ **Điều hướng bàn phím** — mũi tên lên/xuống, Enter để dán, Esc để đóng, ⌘⌫ để xoá
- 📥 **Tự động dán** — chọn item → dán thẳng vào app đang mở (cần quyền Accessibility)
- 🔒 **Riêng tư** — bỏ qua nội dung ẩn (mật khẩu/OTP) và danh sách app bị bỏ qua
- 🗑️ **Retention** — tự giữ tối đa N mục mới nhất (mặc định 1000)
- 🍔 Chạy trên **menu bar**, không chiếm Dock (`LSUIElement`)

## Yêu cầu

- macOS 14+ (Sonoma trở lên)
- Xcode 16+ / Swift 6.0+ (đã kiểm thử với Swift 6.2, Xcode 26)

## Build & chạy

### Cách 1 — Đóng gói `.app` rồi mở (khuyến nghị)

Đây là cách chạy đúng như một menu bar app thật (có icon trên thanh menu, ẩn khỏi Dock).

```bash
# Build bản release + đóng gói thành dist/CopyClipPro.app
./scripts/package.sh release

# Mở app (icon 📋 sẽ xuất hiện trên thanh menu)
open dist/CopyClipPro.app
```

> ⚠️ **Phải chạy qua `.app`**, không chạy binary trần. Menu bar app cần `Info.plist`
> (khoá `LSUIElement`) trong bundle thì status item mới hoạt động đúng.

Script [scripts/package.sh](scripts/package.sh) sẽ tự: `swift build -c release` → tạo
`dist/CopyClipPro.app` với `Info.plist` → ký ad-hoc để chạy cục bộ. Truyền `debug`
thay cho `release` để đóng gói bản debug: `./scripts/package.sh debug`.

### Cách 2 — Build thủ công bằng SwiftPM

```bash
swift build -c release                 # biên dịch, ra .build/release/CopyClipPro
swift build                            # bản debug (mặc định)
swift run                              # build + chạy nhanh khi phát triển
```

`swift run` tiện để thử logic nhưng chạy như tiến trình thường (không có bundle) —
với menu bar app nên ưu tiên **Cách 1** để trải nghiệm đầy đủ.

### Build lại & cài đè (workflow thường dùng)

```bash
pkill -x CopyClipPro                    # tắt bản đang chạy (nếu có)
./scripts/package.sh release            # build + đóng gói lại
open dist/CopyClipPro.app               # mở bản mới
```

### Mở bằng Xcode (tuỳ chọn)

```bash
open Package.swift                      # Xcode mở SwiftPM package, bấm ⌘R để chạy
```

---

Sau khi mở, tìm icon 📋 trên thanh menu. Bấm để mở, hoặc nhấn **⌘⇧V**.

> Để bật **tự động dán**, vào Cài đặt → Dán → Cấp quyền Accessibility (System Settings → Privacy & Security → Accessibility).

## Phân phối sang máy Mac khác

> ⚠️ Đây là app **macOS native** — **không dùng Docker được** (Docker chạy Linux, không có AppKit/menu bar/clipboard của macOS). Máy đích phải là **macOS 14+**.

```bash
./scripts/make-dist.sh     # tạo universal .app + .zip + .dmg trong dist/
```

Copy `dist/CopyClipPro.dmg` sang máy Mac khác → kéo vào `/Applications`. Lần đầu gỡ chặn Gatekeeper:
```bash
xattr -cr "/Applications/CopyClipPro.app"
```
Chi tiết ký/notarize để phát hành sạch: xem [docs/RELEASE.md](docs/RELEASE.md).

## Kiến trúc

Dự án theo **Clean Architecture phân lớp + MVVM**. Xem chi tiết tại [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).

```
App (Composition Root)
  └─ Presentation (SwiftUI Views)
       └─ Application (ViewModel, Settings)
            └─ Domain (Entities, Repository protocol)   ← không phụ thuộc framework
                 └─ Infrastructure (SQLite, Pasteboard, Hotkey)
```

Nguyên tắc: **phụ thuộc luôn hướng vào trong**. UI và ViewModel chỉ biết `ClipboardRepository` (protocol) — không hề biết SQLite, nên dễ test và dễ thay backend.

## Cấu trúc thư mục

```
Sources/CopyClipPro/
├── App/                  # main.swift, AppController (wiring, status item, popover)
├── Presentation/         # HistoryView, HistoryRow, SettingsView
├── Application/          # HistoryViewModel, AppSettings
├── Domain/               # ClipboardItem, ClipboardRepository (protocol)
└── Infrastructure/
    ├── Persistence/      # SQLiteDatabase, SQLiteClipboardRepository
    ├── Clipboard/        # ClipboardMonitor, PasteService
    └── Hotkey/           # GlobalHotkey (Carbon)
```

## Lộ trình

Xem [docs/ROADMAP.md](docs/ROADMAP.md). Tiếp theo: Image/File preview, Snippets, launch-at-login, Sparkle auto-update, notarization.

## Giấy phép

Nội bộ / chưa phát hành.
