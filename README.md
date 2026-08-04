# SnapClip

Trình quản lý lịch sử clipboard **native cho macOS**, viết bằng **Swift + SwiftUI +
AppKit**, lưu trữ bằng **SQLite**. Zero-dependency — chỉ dùng API chính thức của Apple.

Mọi thứ bạn copy đều được ghi lại và gọi lại được bằng **⌘⌥V**. Dữ liệu nằm trọn
trên máy bạn: không tài khoản, không máy chủ, không một lệnh gọi mạng nào.

> Lấy cảm hứng từ CopyClip, Maccy và Raycast Clipboard History, nhưng có kiến trúc
> phân lớp riêng, dễ mở rộng và bảo trì. Mục tiêu: chất lượng phát hành thật.

## Tính năng

**Ghi và tìm lại**

- 📋 Tự động ghi lại mọi nội dung được copy, kèm ứng dụng nguồn và thời điểm
- 🔍 Tìm kiếm tức thì — debounce 120ms, truy vấn LIKE trên chỉ mục SQLite
- 🧬 Chống trùng lặp theo hash nội dung (FNV-1a)
- 🗑️ Retention tự động — giữ N mục mới nhất, mặc định 1.000, chỉnh được 50–100.000

**Bảy loại nội dung**

Văn bản · Liên kết · Mã màu (hex, rgb/rgba, tên màu CSS) · Hình ảnh (PNG kèm
thumbnail) · Tệp tin (security-scoped bookmark) · Rich text (giữ nguyên RTF) ·
Snippet do bạn tự tạo. Mỗi loại có biểu tượng và bản xem trước riêng, kèm màn hình
chi tiết cho nội dung dài.

**Tổ chức**

- 📌 Ghim và ⭐ yêu thích — được bảo vệ khỏi cơ chế dọn dẹp tự động
- 🏷️ Gắn thẻ (tag) và lọc theo thẻ, theo mục yêu thích hoặc theo snippet

**Thao tác**

- ⌨️ Phím tắt toàn cục **⌘⌥V**, đăng ký qua Carbon Event Manager nên không cần
  quyền Accessibility. Nếu tổ hợp bị ứng dụng khác chiếm, app tự lùi sang
  ⌃⌥⌘V → ⌃⌥V → ⌘⌥C
- ↕️ Điều hướng hoàn toàn bằng bàn phím
- 📥 Tự động dán — chọn item rồi Enter là nội dung vào thẳng cửa sổ đang gõ

**Riêng tư**

- 🔒 Tôn trọng cờ `concealed`/`transient` của macOS, đồng thời tự nhận diện mã OTP
  6 số, số thẻ, token dài và các dòng chứa `password`, `secret`, `token`…
- 🚫 Danh sách ứng dụng loại trừ, chọn trực quan từ các app đang chạy
  (Keychain Access nằm sẵn trong mặc định)
- 🔐 Mã hoá nội dung tuỳ chọn bằng AES-GCM 256-bit (CryptoKit), khoá sinh và giữ
  trong Keychain, chỉ đọc được khi máy đã mở khoá

## Yêu cầu

- macOS 14 Sonoma trở lên
- Swift 6.0+ / Xcode 16+ để build (đã kiểm thử với Swift 6.2)

## Build & chạy

### Cách 1 — Đóng gói `.app` (chuẩn, khuyến nghị)

Đây là cách chạy đúng như một app thật, có icon trên thanh menu và đọc được
`Info.plist`.

```bash
./scripts/package.sh release    # build release + đóng gói dist/SnapClip.app
open dist/SnapClip.app          # icon 📋 xuất hiện trên thanh menu
```

Sau khi mở, bấm icon 📋 trên thanh menu hoặc nhấn **⌘⌥V**.

Script [scripts/package.sh](scripts/package.sh) tự làm: `swift build -c release` →
dựng `dist/SnapClip.app` kèm `Info.plist` → ký ad-hoc để chạy cục bộ. Truyền
`debug` thay cho `release` để đóng gói bản debug.

### Cách 2 — Chạy nhanh khi phát triển

```bash
swift run                       # build + chạy ngay, vòng lặp sửa–thử nhanh nhất
swift build                     # bản debug, chỉ biên dịch
swift build -c release          # bản release, ra .build/release/SnapClip
```

> ⚠️ `swift run` chạy như tiến trình thường, **không có bundle** nên thiếu
> `Info.plist` — tiện để thử logic, nhưng muốn trải nghiệm đầy đủ thì dùng Cách 1.
> Đừng gọi thẳng binary trong `.build/` để dùng hằng ngày.

### Build lại và cài đè

```bash
pkill -x SnapClip
./scripts/package.sh release
open dist/SnapClip.app
```

### Mở bằng Xcode

```bash
open Package.swift              # Xcode mở SwiftPM package → chọn scheme SnapClip → ⌘R
```

## Phím tắt

| Phím | Tác dụng               |
| ---- | ---------------------- |
| ⌘⌥V  | Mở / đóng bảng lịch sử |
| ↑ ↓  | Di chuyển giữa các mục |
| ⏎    | Dán mục đang chọn      |
| ⎋    | Đóng bảng lịch sử      |
| ⌘⌫   | Xoá mục đang chọn      |

## Quyền hệ thống

| Quyền         | Khi nào cần                                                         |
| ------------- | ------------------------------------------------------------------- |
| Không cần gì  | Ghi lịch sử, tìm kiếm, phím tắt toàn cục                            |
| Accessibility | Chỉ khi bật **tự động dán** — macOS bắt buộc để mô phỏng thao tác ⌘V |

Cấp quyền tại Cài đặt → Dán → Cấp quyền, hoặc System Settings → Privacy &
Security → Accessibility.

## Dữ liệu lưu ở đâu

| Thứ               | Vị trí                                                  |
| ----------------- | ------------------------------------------------------- |
| Lịch sử clipboard | `~/Library/Application Support/SnapClip/history.sqlite`  |
| Cấu hình          | `UserDefaults` (domain `vn.dipro.snapclip`)             |
| Khoá mã hoá       | Keychain, tag `com.snapclip.encryptionKey`              |

Schema dùng `PRAGMA user_version` để migrate tăng dần (hiện ở version 4), có chỉ
mục cho `created_at`, `content_hash`, cờ pin/favorite, `tags` và `is_snippet`.
Gỡ app và xoá thư mục trên là dữ liệu biến mất hoàn toàn.

## Phân phối sang máy Mac khác

> Đây là app macOS native — **không chạy được trong Docker** (Docker là Linux,
> không có AppKit, menu bar hay pasteboard của macOS). Máy đích phải là macOS 14+.

```bash
./scripts/make-dist.sh          # universal .app + .zip + .dmg trong dist/
```

Copy `dist/SnapClip.dmg` sang máy đích → kéo vào `/Applications`. Bản dựng hiện ký
ad-hoc và chưa notarize nên lần đầu cần gỡ chặn Gatekeeper:

```bash
xattr -cr "/Applications/SnapClip.app"
```

Quy trình ký Developer ID + notarize để phát hành sạch: xem [docs/RELEASE.md](docs/RELEASE.md).

## Kiến trúc

**Clean Architecture phân lớp + MVVM**. Phụ thuộc luôn hướng vào trong: UI và
ViewModel chỉ biết protocol `ClipboardRepository`, không hề biết SQLite — nhờ vậy
dễ test và dễ thay backend lưu trữ.

```
App (Composition Root)
  └─ Presentation (SwiftUI Views)
       └─ Application (ViewModel, Settings)
            └─ Domain (Entities, Repository protocol)   ← không phụ thuộc framework
                 └─ Infrastructure (SQLite, Pasteboard, Hotkey)
```

```
Sources/SnapClip/
├── App/                  # main.swift, AppController, FloatingPanel
├── Presentation/         # HistoryView, HistoryRow, DetailView, SettingsView
├── Application/          # HistoryViewModel, AppSettings
├── Domain/               # ClipboardItem, ClipboardRepository (protocol)
└── Infrastructure/
    ├── Persistence/      # SQLiteDatabase, SQLiteClipboardRepository
    ├── Clipboard/        # ClipboardMonitor, PasteService, Image/File/RichText utils
    └── Hotkey/           # GlobalHotkey (Carbon)
```

Chi tiết đầy đủ và lý do chọn từng pattern: [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).

## Kiểm thử

```bash
swift test
```

8 test trên Swift Testing, phủ entity, hash, preview và query mặc định. Cách viết
test và kịch bản kiểm thử tay: [docs/TESTING.md](docs/TESTING.md).

## Hiệu năng mục tiêu

| Chỉ số                        | Mục tiêu |
| ----------------------------- | -------- |
| Mở bảng lịch sử               | < 100 ms |
| Tìm kiếm trên 100.000 bản ghi | < 50 ms  |
| RAM khi lưu 100.000 bản ghi   | < 150 MB |
| CPU khi rảnh                  | ~ 0%     |
| Thời gian khởi động           | < 300 ms |

## Tài liệu

- [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) — kiến trúc, pattern và lý do chọn
- [docs/TESTING.md](docs/TESTING.md) — chiến lược kiểm thử
- [docs/RELEASE.md](docs/RELEASE.md) — ký, notarize và phát hành
- [docs/ROADMAP.md](docs/ROADMAP.md) — lộ trình theo sprint
- [../landing-page](../landing-page) — trang giới thiệu và tải về (Next.js)

## Lộ trình

Sprint 1–6 đã hoàn thành. Tiếp theo: launch-at-login (SMAppService), iCloud Sync,
plugin system, AI search. Chi tiết: [docs/ROADMAP.md](docs/ROADMAP.md).

## Giấy phép

[MIT](LICENSE) © 2026 SnapClip. Được tự do dùng, sửa và phân phối, miễn giữ lại
thông báo bản quyền và giấy phép.
