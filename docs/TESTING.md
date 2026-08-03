# Testing Guide

## Kiến trúc test

Dùng **Swift Testing** framework (Xcode 16+), không dùng XCTest.

```
Tests/SnapClipTests/
├── ClipboardItemTests.swift    # Domain entity tests
├── HistoryViewModelTests.swift # ViewModel tests (TODO)
└── SQLiteRepositoryTests.swift # Repository integration tests (TODO)
```

## Chạy test

```bash
# Chạy tất cả test
swift test

# Chạy test cụ thể
swift test --filter ClipboardItemTests

# Chạy verbose
swift test -v
```

## Coverage mục tiêu

| Layer                   | Coverage | Ghi chú                       |
| ----------------------- | -------- | ----------------------------- |
| Domain (ClipboardItem)  | 100%     | Logic thuần, không dependency |
| Application (ViewModel) | 80%+     | Mock repository               |
| Infrastructure (SQLite) | 70%+     | Integration test với temp DB  |
| Presentation (Views)    | Manual   | SwiftUI preview + snapshot    |

## Mock repository

Dùng `MockClipboardRepository` cho ViewModel tests:

```swift
final class MockClipboardRepository: ClipboardRepository {
    var items: [ClipboardItem] = []
    func insert(_ item: ClipboardItem) throws -> ClipboardItem { ... }
    func fetch(_ query: HistoryQuery) throws -> [ClipboardItem] { ... }
    // ...
}
```

## Performance test

```bash
# Insert N items và đo thời gian
swift test --filter PerformanceTests
```

KPI:

- Popover open < 100ms
- Search (100k items) < 50ms
- RAM idle ~50MB
