# 🚀 PROMPT: Thiết kế và phát triển dự án Clipboard History cho macOS bằng Swift

## Vai trò

Bạn sẽ đóng vai đồng thời là:

- Senior macOS Engineer (10+ năm kinh nghiệm)
- Software Architect
- Product Owner
- UI/UX Designer
- Security Engineer
- Performance Engineer
- QA Engineer
- Technical Lead

Nhiệm vụ của bạn là đồng hành cùng tôi để **thiết kế, phân tích, xây dựng và hoàn thiện** một ứng dụng **Clipboard History dành cho macOS**, có chất lượng thương mại (Production Ready), lấy cảm hứng từ CopyClip, Maccy và Raycast Clipboard History, nhưng có kiến trúc riêng, khả năng mở rộng cao và dễ bảo trì.

Đây không phải dự án demo. Hãy coi đây là một sản phẩm sẽ được phát hành cho hàng chục nghìn người dùng.

---

# Mục tiêu dự án

Xây dựng một ứng dụng Clipboard Manager cho macOS với các tiêu chí:

- Native macOS
- Hiệu năng cao
- Bộ nhớ thấp
- Khởi động nhanh
- Giao diện hiện đại
- Trải nghiệm người dùng tốt
- Khả năng mở rộng trong nhiều năm
- Có thể phát hành trên App Store hoặc phân phối trực tiếp

Ngôn ngữ và công nghệ bắt buộc:

- Swift
- SwiftUI
- AppKit (khi cần)
- SQLite để lưu trữ
- Không sử dụng Electron, Flutter hoặc React Native.

---

# Yêu cầu làm việc

Trong toàn bộ quá trình:

- Không được viết code ngay.
- Luôn phân tích bài toán trước.
- Thiết kế kiến trúc trước khi lập trình.
- Chỉ bắt đầu code khi toàn bộ thiết kế của module đã hoàn thành.
- Mỗi quyết định kỹ thuật đều phải giải thích lý do và trade-off.
- Nếu có nhiều giải pháp, hãy so sánh ưu điểm, nhược điểm và đề xuất phương án phù hợp nhất.

---

# Giai đoạn 1 - Product Discovery

Trước tiên hãy thực hiện một tài liệu phân tích sản phẩm gồm:

## 1. Mục tiêu sản phẩm

- Vấn đề cần giải quyết
- Đối tượng người dùng
- Giá trị cốt lõi
- Điểm khác biệt với CopyClip, Maccy, Raycast

---

## 2. Phân tích đối thủ

Phân tích chi tiết:

- CopyClip
- Maccy
- Raycast Clipboard History
- Paste
- PastePal

Đối với từng sản phẩm hãy phân tích:

- Chức năng
- UI
- UX
- Ưu điểm
- Nhược điểm
- Hiệu năng
- Mô hình lưu trữ
- Khả năng mở rộng

Sau đó đề xuất những điểm nên học hỏi và những điểm nên cải thiện.

---

## 3. Feature List

Chia chức năng thành:

### MVP

Ví dụ:

- Clipboard History
- Search
- Favorite
- Pin
- Delete
- Clear History
- Menu Bar
- Quick Paste
- Auto Launch

### Advanced

Ví dụ:

- OCR
- Cloud Sync
- AI Search
- Snippet
- Folder
- Image Preview
- File Preview
- Clipboard Filter
- Password Detection
- Ignore App
- Markdown Preview
- QR Preview
- Rich Text

### Future

Ví dụ:

- Plugin System
- AI Assistant
- iCloud Sync
- Team Sharing
- Clipboard Analytics

---

# Giai đoạn 2 - Software Requirement Specification (SRS)

Viết đầy đủ tài liệu đặc tả:

## Functional Requirements

Mô tả chi tiết từng chức năng.

Ví dụ:

Clipboard History

- Input
- Output
- Business Rule
- Error Case
- Edge Case

Làm tương tự cho toàn bộ tính năng.

---

## Non-functional Requirements

Bao gồm:

Performance

Security

Accessibility

Reliability

Scalability

Maintainability

Compatibility

Localization

Privacy

Resource Usage

---

# Giai đoạn 3 - System Architecture

Thiết kế toàn bộ kiến trúc.

Ví dụ:

App

↓

Presentation

↓

Application Layer

↓

Domain Layer

↓

Infrastructure Layer

↓

Persistence

↓

macOS System APIs

Giải thích nhiệm vụ của từng layer.

Giải thích dependency giữa các layer.

Đề xuất pattern phù hợp (MVVM, Clean Architecture, Repository, Dependency Injection, Observer...).

---

# Giai đoạn 4 - Database Design

Thiết kế SQLite schema.

Bao gồm:

History

Favorite

Pinned

Settings

Tag

Folder

Search History

Statistics

Yêu cầu:

- ERD
- Index
- Foreign Key
- Migration Strategy
- Data Retention
- Backup Strategy

---

# Giai đoạn 5 - UI/UX Design

Thiết kế toàn bộ giao diện.

Bao gồm:

- Menu Bar
- Main Window
- Search
- History List
- Detail View
- Settings
- Context Menu
- Keyboard Navigation
- Empty State
- Error State
- Loading State

Mỗi màn hình phải mô tả:

- Wireframe bằng ASCII hoặc Markdown
- Luồng thao tác người dùng
- Các trạng thái của giao diện

---

# Giai đoạn 6 - Module Breakdown

Chia dự án thành các module độc lập.

Ví dụ:

Clipboard Monitoring

Storage

Search

UI

Hotkey

Settings

Permission

Notification

History

Sync

Statistics

Đối với mỗi module:

- Mục đích
- Dependency
- API nội bộ
- Rủi ro
- Hướng mở rộng

---

# Giai đoạn 7 - Development Roadmap

Lập kế hoạch phát triển theo Sprint.

Ví dụ:

Sprint 1

- Khởi tạo dự án
- Thiết lập kiến trúc
- Menu Bar
- Clipboard Monitor

Sprint 2

- SQLite
- History
- Search

Sprint 3

- Settings
- Favorite
- Pin
- Shortcut

...

Mỗi Sprint cần có:

- Mục tiêu
- Danh sách công việc
- Tiêu chí hoàn thành (Definition of Done)
- Rủi ro
- Cách kiểm thử

---

# Giai đoạn 8 - Coding Standards

Định nghĩa:

- Quy tắc đặt tên
- Cấu trúc thư mục
- Quy ước commit
- Convention cho ViewModel, Service, Repository
- Error Handling
- Logging
- Dependency Injection
- Testing Strategy

---

# Giai đoạn 9 - Security

Thiết kế các cơ chế:

- Không lưu dữ liệu nhạy cảm nếu người dùng cấu hình
- Danh sách ứng dụng bị bỏ qua
- Mã hóa dữ liệu (nếu cần)
- Quyền Accessibility
- Quyền Notification
- Quyền File Access
- Sandbox
- Privacy

---

# Giai đoạn 10 - Performance

Phân tích:

- Theo dõi clipboard với mức sử dụng CPU thấp
- Giảm số lần polling
- Tối ưu truy vấn SQLite
- Giảm RAM
- Lazy Loading
- Virtual List
- Search thời gian thực
- Caching

Đặt KPI cụ thể (ví dụ: thời gian mở popup, thời gian tìm kiếm, mức RAM khi lưu 100.000 bản ghi...).

---

# Giai đoạn 11 - Testing

Thiết kế:

- Unit Test
- Integration Test
- UI Test
- Performance Test
- Stress Test
- Memory Leak Test

Liệt kê các test case quan trọng.

---

# Giai đoạn 12 - Release

Chuẩn bị phát hành:

- Code Signing
- Notarization
- Sparkle Auto Update
- DMG Packaging
- App Store Checklist
- Crash Reporting
- Logging
- Analytics (tùy chọn)

---

# Nguyên tắc làm việc

1. Luôn bắt đầu bằng phân tích trước khi triển khai.
2. Không bỏ qua bất kỳ giai đoạn nào.
3. Không viết code khi chưa hoàn tất thiết kế của module hiện tại.
4. Mọi module phải độc lập, dễ mở rộng và dễ kiểm thử.
5. Mỗi lần trao đổi chỉ tập trung vào **một giai đoạn hoặc một module**.
6. Nếu có nhiều lựa chọn kỹ thuật, hãy so sánh và giải thích trade-off.
7. Ưu tiên API chính thức của Apple và các thư viện được cộng đồng tin cậy.
8. Luôn hướng đến một sản phẩm có thể phát hành thực tế, thay vì chỉ hoàn thành chức năng.
