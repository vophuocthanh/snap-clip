import Foundation

/// Type of content stored in clipboard history.
/// In MVP, we focus on text; images/files/RTF are reserved for Advanced phase.
enum ClipboardContentType: String, Codable, Sendable, CaseIterable {
    case text
    case url
    case color
    case image
    case file
    case richText

    /// Name of SF Symbol used for display icon in list.
    var symbolName: String {
        switch self {
        case .text: return "text.alignleft"
        case .url: return "link"
        case .color: return "paintpalette"
        case .image: return "photo"
        case .file: return "doc"
        case .richText: return "textformat"
        }
    }
}

/// Entity cốt lõi của Domain layer — một bản ghi trong clipboard history.
///
/// Bất biến về mặt danh tính (`id`), các cờ trạng thái (`isPinned`, `isFavorite`)
/// có thể thay đổi. Là `Sendable` để an toàn khi truyền qua các actor/thread
/// (monitor chạy nền, UI chạy main).
struct ClipboardItem: Identifiable, Hashable, Sendable {
    let id: UUID
    /// Nội dung dạng text đã chuẩn hoá (dùng cho hiển thị + tìm kiếm).
    var content: String
    /// Hash của nội dung để chống trùng lặp nhanh mà không so sánh chuỗi dài.
    let contentHash: String
    var type: ClipboardContentType
    let createdAt: Date
    var isPinned: Bool
    var isFavorite: Bool
    /// Bundle id của app nguồn đã copy (vd: com.google.Chrome), có thể nil.
    let sourceAppBundleId: String?
    /// Tên hiển thị của app nguồn.
    let sourceAppName: String?
    /// Dữ liệu ảnh đầy đủ (PNG) — chỉ có khi vừa tạo/khi cần paste; nil khi tải danh sách.
    var imageData: Data?
    /// Thumbnail PNG nhỏ để hiển thị nhanh trong danh sách (chỉ có với item ảnh).
    var thumbnailData: Data?

    init(
        id: UUID = UUID(),
        content: String,
        contentHash: String? = nil,
        type: ClipboardContentType = .text,
        createdAt: Date = Date(),
        isPinned: Bool = false,
        isFavorite: Bool = false,
        sourceAppBundleId: String? = nil,
        sourceAppName: String? = nil,
        imageData: Data? = nil,
        thumbnailData: Data? = nil
    ) {
        self.id = id
        self.content = content
        self.contentHash = contentHash ?? ClipboardItem.hash(for: content)
        self.type = type
        self.createdAt = createdAt
        self.isPinned = isPinned
        self.isFavorite = isFavorite
        self.sourceAppBundleId = sourceAppBundleId
        self.sourceAppName = sourceAppName
        self.imageData = imageData
        self.thumbnailData = thumbnailData
    }

    /// Dòng tóm tắt hiển thị (1 dòng, cắt khoảng trắng thừa).
    var preview: String {
        let collapsed = content
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "\t", with: " ")
        let trimmed = collapsed.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "(trống)" : trimmed
    }

    /// Hash ổn định (FNV-1a) dùng cho dedup. Không cần bảo mật, chỉ cần nhanh.
    static func hash(for content: String) -> String {
        hash(for: Array(content.utf8))
    }

    /// Hash dữ liệu nhị phân (dùng cho ảnh).
    static func hash(for data: Data) -> String {
        hash(for: Array(data))
    }

    private static func hash<S: Sequence>(for bytes: S) -> String where S.Element == UInt8 {
        var hash: UInt64 = 0xcbf29ce484222325
        let prime: UInt64 = 0x100000001b3
        for byte in bytes {
            hash ^= UInt64(byte)
            hash = hash &* prime
        }
        return String(hash, radix: 16)
    }
}
