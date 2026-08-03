# Kiến trúc SnapClip

## 1. Tổng quan

SnapClip áp dụng **Clean Architecture phân lớp** kết hợp **MVVM** cho tầng trình bày. Mục tiêu: tách biệt rõ ràng, dễ kiểm thử, dễ mở rộng trong nhiều năm, và giữ Domain hoàn toàn độc lập với framework của Apple.

```
┌─────────────────────────────────────────────┐
│  App  (Composition Root)                     │  main.swift, AppController, FloatingPanel
│  - Khởi tạo & nối mọi thành phần (DI thủ công)│
│  - Quản lý status item, panel, Dock, hotkey   │
└───────────────┬─────────────────────────────┘
                │
┌───────────────▼─────────────────────────────┐
│  Presentation (SwiftUI)                       │  HistoryView, HistoryRow, SettingsView
│  - Chỉ hiển thị & bắt sự kiện người dùng      │
└───────────────┬─────────────────────────────┘
                │  (ObservableObject)
┌───────────────▼─────────────────────────────┐
│  Application                                  │  HistoryViewModel, AppSettings
│  - Điều phối use-case, trạng thái UI          │
└───────────────┬─────────────────────────────┘
                │  (protocol ClipboardRepository)
┌───────────────▼─────────────────────────────┐
│  Domain (thuần Swift, không framework)        │  ClipboardItem, ClipboardRepository
│  - Entity + quy tắc nghiệp vụ + cổng (port)   │
└───────────────┬─────────────────────────────┘
                │  (cài đặt protocol)
┌───────────────▼─────────────────────────────┐
│  Infrastructure                               │  SQLite*, ClipboardMonitor, PasteService,
│  - Chi tiết kỹ thuật: DB, pasteboard,         │  ImageUtils, GlobalHotkey
│    ảnh, hotkey                                │
└─────────────────────────────────────────────┘
```

**Quy tắc phụ thuộc (Dependency Rule):** mã ở lớp trong không bao giờ biết lớp ngoài. `Domain` không import AppKit/SQLite. `Application` chỉ biết `ClipboardRepository` (một protocol trong Domain). Nhờ đó có thể mock repository để unit-test ViewModel mà không cần DB thật.

## 2. Vì sao chọn các pattern này

| Pattern | Lý do | Trade-off |
|---|---|---|
| **MVVM** | SwiftUI vốn hợp với ViewModel `ObservableObject`; tách logic khỏi View | Cần cẩn thận vòng đời `@Published`/`Task` |
| **Repository (port/adapter)** | Đổi backend (SQLite → CoreData/CloudKit) không đụng UI | Thêm 1 lớp abstraction |
| **DI thủ công tại Composition Root** | Minh bạch, không cần thư viện DI, dễ đọc | Phải tự nối; đủ tốt ở quy mô này |
| **Vòng đời AppKit thủ công** (không `@main` SwiftUI App) | Kiểm soát trọn vẹn status item + panel + hotkey | Nhiều code lệnh hơn `MenuBarExtra` |

## 3. Các quyết định kỹ thuật chính

### 3.1 Theo dõi clipboard — polling `changeCount`
macOS **không** phát notification công khai khi pasteboard đổi. Cách chuẩn là poll `NSPasteboard.changeCount` (một `Int` tăng dần). So sánh số nguyên rất rẻ; chỉ khi đổi mới thực sự đọc nội dung → CPU ~0% khi rảnh. Interval mặc định 0.4s cân bằng độ trễ cảm nhận và tải hệ thống. Xem [ClipboardMonitor.swift](../Sources/SnapClip/Infrastructure/Clipboard/ClipboardMonitor.swift).

### 3.2 Global hotkey — Carbon `RegisterEventHotKey`
Không cần quyền Accessibility (khác `CGEventTap`), là API chính thức và ổn định nhất cho global hotkey. Zero-dependency. `setupHotkey()` thử lần lượt một danh sách combo (**⌘⌥V → ⌃⌥⌘V → ⌃⌥V → ⌘⌥C**) và lấy combo đầu tiên đăng ký được — vì `RegisterEventHotKey` sẽ **thất bại** nếu combo đã bị app khác chiếm (vd Raycast giữ ⌘⇧V). Xem [GlobalHotkey.swift](../Sources/SnapClip/Infrastructure/Hotkey/GlobalHotkey.swift).

### 3.3 Lưu trữ — SQLite qua C API
Dùng `libsqlite3` có sẵn trong macOS (không thêm package). Bật **WAL** để ghi nhanh & đọc không chặn ghi, `synchronous = NORMAL` cân bằng an toàn/tốc độ. Mọi truy cập serialize qua một `DispatchQueue` nội bộ. Index trên `created_at`, `content_hash`, và cờ pin/favorite. Dedup bằng FNV-1a hash (áp dụng cho cả chuỗi text lẫn byte ảnh) để tránh so sánh dữ liệu dài.

### 3.4 Lưu hình ảnh — BLOB + thumbnail tách rời
Item ảnh lưu **2 cột BLOB**: `image_data` (PNG gốc, dùng khi paste/preview) và `thumbnail_data` (PNG ≤240px, dùng hiển thị danh sách). Điểm mấu chốt về hiệu năng: **`fetch()` cho danh sách CHỈ tải `thumbnail_data`** (~vài chục KB), ảnh gốc (~vài trăm KB) chỉ nạp theo yêu cầu qua `imageData(id:)` khi người dùng chọn để paste → danh sách luôn nhẹ dù chứa nhiều ảnh. `ClipboardMonitor` nhận diện ảnh từ nhiều nguồn: dữ liệu ảnh trực tiếp (png/tiff — screenshot ⌘⇧⌃4, copy ảnh), file ảnh copy từ Finder (file-url), và `NSImage(pasteboard:)` dự phòng. Chuyển đổi/thu nhỏ ở [ImageUtils.swift](../Sources/SnapClip/Infrastructure/Clipboard/ImageUtils.swift).

### 3.5 Cửa sổ chính — `FloatingPanel` thay vì `NSPopover`
`NSPopover` luôn ghim mũi tên sát nút status item nên không tạo được khoảng hở với menu bar và không kiểm soát được màn hình hiển thị. Ta dùng một [FloatingPanel](../Sources/SnapClip/App/FloatingPanel.swift) (subclass `NSPanel`) để tự do định vị + bo góc + đổ bóng như Raycast.

> **Bài học quan trọng:** styleMask phải **tối giản `[.borderless]`**. Tổ hợp `.nonactivatingPanel + .fullSizeContentView` kèm override `canBecomeKey` từng gây **treo `NSPanel.init`** → panel không tạo xong → hotkey (chạy ngay sau) không đăng ký. Đây là gốc của loạt lỗi "panel == nil" và "hotkey không ăn".

### 3.6 Định vị panel đa màn hình
`showPopover()` mở panel trên **màn hình đang có con trỏ chuột** (`NSEvent.mouseLocation`), không bám cứng vào nút status — vì trong setup nhiều màn hình, macOS có thể đặt status item ở màn hình khác. Nhờ vậy panel luôn hiện đúng nơi người dùng đang thao tác.

### 3.7 Chế độ app: regular (có Dock icon)
App chạy `NSApp.setActivationPolicy(.regular)` + `LSUIElement=false` → có icon Dock làm điểm truy cập luôn nhìn thấy. Click Dock được xử lý qua `applicationShouldHandleReopen`. Lý do: trong một số cấu hình đa màn hình, macOS không cấp slot menu bar cho status item của app accessory; Dock icon đảm bảo luôn có đường vào. (Đổi về menu-bar-only: `LSUIElement=true` + `.accessory`.)

### 3.8 Concurrency (Swift 6)
- `Domain` entity là `Sendable` → an toàn khi truyền giữa monitor (nền) và UI (main).
- UI/ViewModel/Controller là `@MainActor`.
- Lớp SQLite là `@unchecked Sendable` + tự serialize bằng queue.

## 4. Luồng dữ liệu tiêu biểu

**Copy → lưu:**
```
User copy (app bất kỳ) hoặc chụp màn hình ⌘⇧⌃4
  → ClipboardMonitor.poll() phát hiện changeCount đổi
  → bỏ qua nếu là self-write, concealed, hoặc app bị ignore
  → thử đọc ẢNH trước (png/tiff/file-url); nếu không thì đọc text
  → dựng ClipboardItem (text: content; ảnh: content mô tả + imageData + thumbnailData)
  → AppController.onNewItem: repository.insert() (dedup theo hash) + enforceRetention()
  → historyVM.reload() → UI cập nhật
```

**Chọn → dán:**
```
User mở panel (Dock / ⌘⌥V / click icon) → chọn item (click/Enter)
  → AppController.handleSelect: nếu ảnh, nạp imageData gốc qua repository.imageData(id)
  → PasteService.copyToPasteboard() (text: setString; ảnh: setData PNG)
  → gọi willWriteToPasteboard() SAU khi ghi → monitor bỏ qua đúng changeCount vừa tạo
    (tránh app tự re-capture nội dung mình vừa paste)
  → (nếu bật) synthesize ⌘V vào app đang active
```

## 5. Vài bug tiêu biểu đã xử lý (ghi lại để tránh lặp)

- **`NSPanel.init` treo** do styleMask phức tạp → dùng `[.borderless]` tối giản (§3.5).
- **Hotkey ⌘⇧V trùng Raycast** → danh sách combo dự phòng, lấy combo trống (§3.2).
- **App tự nhân bản clipboard**: `markSelfWrite()` gọi *trước* khi ghi → lệch 1 nhịp `changeCount`. Sửa: gọi *sau* khi ghi (§4, "Chọn → dán").
- **Ảnh hiển thị kẹt ở item cũ**: dùng `.id(index)` trên row xung đột với identity `\.element.id` của ForEach → SwiftUI không cập nhật. Sửa: định danh row theo `item.id`, cuộn theo `item.id`.
- **Crash khi click trong vòng tracking status bar**: hoãn xử lý click ra khỏi `NSControlTrackMouse` bằng `DispatchQueue.main.async`.

## 6. Khả năng kiểm thử

- `HistoryViewModel` nhận `ClipboardRepository` qua init → dễ inject mock in-memory.
- `ClipboardItem.detectType`, `hash`, `preview` là hàm thuần → unit-test trực tiếp.
- `ImageUtils.pngData/thumbnailData` là hàm thuần trên `NSImage`.
- `SQLiteClipboardRepository` có thể test với DB tạm (file temp).

## 7. Điểm mở rộng đã chuẩn bị sẵn

- `ClipboardContentType` đã có `.file/.richText/.color` cho giai đoạn Advanced (ảnh đã hoàn thiện).
- Schema versioning qua `PRAGMA user_version` (hiện ở **v2** — v2 thêm cột ảnh) → migration tăng dần an toàn.
- Repository là protocol → thêm `CloudKitClipboardRepository` cho iCloud Sync sau này.
