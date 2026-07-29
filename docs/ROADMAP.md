# Lộ trình phát triển (Development Roadmap)

Ánh xạ từ `workflow-project.md`. Đánh dấu ✅ đã xong ở MVP hiện tại.

## Sprint 1 — Nền tảng ✅ (hoàn thành)
- ✅ Khởi tạo project SwiftPM + kiến trúc phân lớp
- ✅ Menu bar (NSStatusItem) + popover SwiftUI
- ✅ Clipboard Monitor (polling changeCount)
- ✅ SQLite storage + migration + index
- ✅ Definition of Done: app build & chạy, ghi được history, RAM ~50MB

## Sprint 2 — History & Search ✅ (hoàn thành ở mức MVP)
- ✅ Danh sách history + LazyVStack (ảo hoá nhẹ)
- ✅ Search debounce + index LIKE
- ✅ Dedup theo hash
- ✅ Retention theo số lượng

## Sprint 3 — Tương tác & tiện ích ✅ (phần lớn)
- ✅ Favorite, Pin, Delete, Clear
- ✅ Global hotkey ⌘⇧V
- ✅ Điều hướng bàn phím (↑/↓/Enter/Esc/⌘⌫)
- ✅ Tự động dán (Cmd+V) + xử lý quyền Accessibility
- ✅ Settings cơ bản (retention, privacy, paste)
- ⬜ Launch at Login (SMAppService)

## Sprint 4 — Nội dung phong phú (Advanced)
- ⬜ Lưu & preview **ảnh** (NSImage, lưu blob/đường dẫn)
- ⬜ Lưu & preview **file** (URL bookmark)
- ⬜ **Rich text / RTF**, Markdown preview
- ⬜ Color swatch preview, QR preview
- ⬜ Detail view (xem toàn bộ nội dung dài)

## Sprint 5 — Tổ chức & bảo mật
- ⬜ **Snippets** (mục tạo tay, dán nhanh)
- ⬜ **Folder / Tag** phân loại
- ⬜ **Password detection** nâng cao (heuristic)
- ⬜ Mã hoá DB tuỳ chọn (SQLCipher hoặc mã hoá field)
- ⬜ Ignore app qua picker trực quan

## Sprint 6 — Chất lượng & phát hành
- ⬜ Unit/Integration/UI test (xem docs/TESTING.md — TODO)
- ⬜ Performance test 100k bản ghi (KPI: mở popover < 100ms, search < 50ms)
- ⬜ Code Signing (Developer ID) + Notarization
- ⬜ Sparkle auto-update + DMG packaging
- ⬜ Crash reporting + logging

## Tương lai (Future)
- ⬜ iCloud Sync (CloudKitClipboardRepository)
- ⬜ Plugin system
- ⬜ AI Search / AI Assistant
- ⬜ Clipboard Analytics
- ⬜ Team Sharing

## KPI mục tiêu (Performance)
| Chỉ số | Mục tiêu |
|---|---|
| Thời gian mở popover | < 100 ms |
| Thời gian search (100k bản ghi) | < 50 ms |
| RAM khi lưu 100k bản ghi | < 150 MB |
| CPU khi rảnh (monitor) | ~ 0% |
| Thời gian khởi động | < 300 ms |
