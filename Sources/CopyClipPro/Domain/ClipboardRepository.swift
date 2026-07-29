import Foundation

/// Bộ lọc truy vấn history.
struct HistoryQuery: Sendable {
    var searchText: String = ""
    var onlyFavorites: Bool = false
    var limit: Int = 200
    var offset: Int = 0
}

/// Cổng (port) của Domain layer ra hạ tầng lưu trữ.
///
/// Presentation/Application chỉ phụ thuộc vào protocol này, không biết SQLite.
/// Giúp dễ test (mock in-memory) và dễ đổi backend (CoreData/CloudKit) sau này.
protocol ClipboardRepository: Sendable {
    /// Thêm bản ghi mới. Nếu trùng nội dung với bản mới nhất thì chỉ đẩy thời gian lên.
    /// Trả về item đã lưu (có thể là item cũ được cập nhật).
    func insert(_ item: ClipboardItem) throws -> ClipboardItem

    /// Lấy danh sách theo query (đã sắp xếp: pinned trước, rồi mới nhất trước).
    /// Với item ảnh, chỉ trả về thumbnail (không tải ảnh gốc để giữ danh sách nhẹ).
    func fetch(_ query: HistoryQuery) throws -> [ClipboardItem]

    /// Tải dữ liệu ảnh gốc (PNG) của một item — dùng khi cần paste/preview.
    func imageData(id: UUID) throws -> Data?

    /// Cập nhật cờ pin/favorite của một item.
    func setPinned(_ isPinned: Bool, id: UUID) throws
    func setFavorite(_ isFavorite: Bool, id: UUID) throws

    /// Xoá một item.
    func delete(id: UUID) throws

    /// Xoá toàn bộ history (giữ lại pinned/favorite nếu `keepProtected` = true).
    func clear(keepProtected: Bool) throws

    /// Tổng số bản ghi (phục vụ retention/thống kê).
    func count() throws -> Int

    /// Giữ lại tối đa `maxItems` bản ghi mới nhất (không đụng pinned/favorite).
    func enforceRetention(maxItems: Int) throws
}
