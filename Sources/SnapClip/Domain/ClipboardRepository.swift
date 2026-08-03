import Foundation

/// Bộ lọc truy vấn history.
struct HistoryQuery: Sendable {
    var searchText: String = ""
    var onlyFavorites: Bool = false
    var onlySnippets: Bool = false
    var tag: String = ""
    var limit: Int = 200
    var offset: Int = 0
}

/// Cổng (port) của Domain layer ra hạ tầng lưu trữ.
protocol ClipboardRepository: Sendable {
    /// Thêm bản ghi mới. Nếu trùng nội dung với bản mới nhất thì chỉ đẩy thời gian lên.
    @discardableResult
    func insert(_ item: ClipboardItem) throws -> ClipboardItem

    /// Lấy danh sách theo query.
    func fetch(_ query: HistoryQuery) throws -> [ClipboardItem]

    /// Tạo snippet (item do người dùng tạo tay).
    @discardableResult
    func createSnippet(content: String, tags: String) throws -> ClipboardItem

    /// Cập nhật tags cho một item.
    func updateTags(_ tags: String, id: UUID) throws

    // Full content loading
    func imageData(id: UUID) throws -> Data?
    func richTextData(id: UUID) throws -> Data?
    func resolveFileURL(id: UUID) throws -> URL?

    // Mutations
    func setPinned(_ isPinned: Bool, id: UUID) throws
    func setFavorite(_ isFavorite: Bool, id: UUID) throws
    func delete(id: UUID) throws
    func clear(keepProtected: Bool) throws

    // Maintenance
    func count() throws -> Int
    func allTags() throws -> [String]
    func enforceRetention(maxItems: Int) throws
}
