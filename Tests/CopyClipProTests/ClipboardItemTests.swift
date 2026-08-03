import Testing
import Foundation
@testable import CopyClipPro

/// Tests cho Domain layer: ClipboardItem.
struct ClipboardItemTests {

    @Test("Tạo item text cơ bản")
    func testBasicTextItem() {
        let item = ClipboardItem(content: "Hello, World!")
        #expect(item.content == "Hello, World!")
        #expect(item.type == .text)
        #expect(!item.contentHash.isEmpty)
        #expect(!item.isPinned)
        #expect(!item.isFavorite)
        #expect(!item.isSnippet)
        #expect(item.tags == "")
    }

    @Test("Preview xoá newline và tab")
    func testPreviewCollapsesWhitespace() {
        let item = ClipboardItem(content: "Hello\n\tWorld\nFoo")
        #expect(item.preview == "Hello  World Foo")
    }

    @Test("Preview empty trả về '(trống)'")
    func testPreviewEmptyContent() {
        let item = ClipboardItem(content: "   \n\t   ")
        #expect(item.preview == "(trống)")
    }

    @Test("Hash ổn định cho cùng nội dung")
    func testStableHash() {
        let h1 = ClipboardItem.hash(for: "Hello")
        let h2 = ClipboardItem.hash(for: "Hello")
        #expect(h1 == h2)
    }

    @Test("Hash khác nhau cho nội dung khác")
    func testDifferentHash() {
        let h1 = ClipboardItem.hash(for: "Hello")
        let h2 = ClipboardItem.hash(for: "World")
        #expect(h1 != h2)
    }
}

/// Tests cho ClipboardContentType.
struct ClipboardContentTypeTests {

    @Test("Tất cả type có symbolName")
    func testAllTypesHaveSymbol() {
        for type in ClipboardContentType.allCases {
            #expect(!type.symbolName.isEmpty)
        }
    }

    @Test("Snippet type tồn tại")
    func testSnippetType() {
        #expect(ClipboardContentType.snippet.rawValue == "snippet")
    }
}

/// Tests cho HistoryQuery.
struct HistoryQueryTests {

    @Test("Query mặc định")
    func testDefaultQuery() {
        let q = HistoryQuery()
        #expect(q.searchText == "")
        #expect(q.limit == 200)
        #expect(q.offset == 0)
        #expect(!q.onlyFavorites)
        #expect(!q.onlySnippets)
        #expect(q.tag == "")
    }
}
