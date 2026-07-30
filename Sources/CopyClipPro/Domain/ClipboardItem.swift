import Foundation

/// Type of content stored in clipboard history.
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
/// có thể thay đổi. Là `Sendable` để an toàn khi truyền qua các actor/thread.
struct ClipboardItem: Identifiable, Hashable, Sendable {
    let id: UUID
    /// Nội dung dạng text đã chuẩn hoá (dùng cho hiển thị + tìm kiếm).
    var content: String
    /// Hash của nội dung để chống trùng lặp nhanh.
    let contentHash: String
    var type: ClipboardContentType
    let createdAt: Date
    var isPinned: Bool
    var isFavorite: Bool
    let sourceAppBundleId: String?
    let sourceAppName: String?

    // Image
    /// Dữ liệu ảnh gốc (PNG) — chỉ có khi vừa tạo/khi cần paste; nil khi tải danh sách.
    var imageData: Data?
    /// Thumbnail PNG nhỏ để hiển thị nhanh trong danh sách.
    var thumbnailData: Data?

    /// Dữ liệu RTF gốc — dùng để paste lại hoặc hiển thị rich preview.
    var richTextData: Data?

    // File
    /// Security-scoped bookmark cho phép truy cập file gốc.
    var fileBookmark: Data?
    /// Đường dẫn gốc của file (hiển thị cho người dùng).
    var filePath: String?
    /// UTI của file (public.plain-text, public.jpeg, …).
    var fileUTI: String?

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
        thumbnailData: Data? = nil,
        richTextData: Data? = nil,
        fileBookmark: Data? = nil,
        filePath: String? = nil,
        fileUTI: String? = nil
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
        self.richTextData = richTextData
        self.fileBookmark = fileBookmark
        self.filePath = filePath
        self.fileUTI = fileUTI
    }

    /// Dòng tóm tắt hiển thị (1 dòng) tuỳ theo loại nội dung.
    var preview: String {
        switch type {
        case .image:
            return content
        case .file:
            return filePath.flatMap { URL(fileURLWithPath: $0).lastPathComponent }
                ?? content
        case .richText:
            return content
        case .color:
            return content
        case .url:
            return content
        case .text:
            let collapsed = content
                .replacingOccurrences(of: "\n", with: " ")
                .replacingOccurrences(of: "\t", with: " ")
            let trimmed = collapsed.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? "(trống)" : trimmed
        }
    }

    /// Nội dung mô tả phụ (dòng 2) — kích thước ảnh, tên app, v.v.
    var subtitle: String {
        switch type {
        case .image:
            return sourceAppName ?? "Hình ảnh"
        case .file:
            let name = filePath.flatMap { URL(fileURLWithPath: $0).lastPathComponent } ?? ""
            let uti = fileUTI ?? ""
            return [name, uti].filter { !$0.isEmpty }.joined(separator: " · ")
        case .richText:
            return sourceAppName ?? "Rich Text"
        case .color:
            return "Màu sắc"
        default:
            return sourceAppName ?? ""
        }
    }

    /// Hash ổn định (FNV-1a) dùng cho dedup.
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
