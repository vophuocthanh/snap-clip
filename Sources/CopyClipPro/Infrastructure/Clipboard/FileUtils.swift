import AppKit
import UniformTypeIdentifiers

/// Tiện ích xử lý file từ pasteboard: đọc thông tin, tạo bookmark.
enum FileUtils {
    /// Đọc danh sách file URL từ pasteboard và trả về metadata cho mỗi file.
    /// - Returns: Mảng các tuple chứa thông tin file, rỗng nếu pasteboard không có file.
    static func readFileURLs(from pasteboard: NSPasteboard) -> [(path: String, uti: String)] {
        guard let urls = pasteboard.readObjects(forClasses: [NSURL.self]) as? [URL] else {
            return []
        }
        return urls
            .filter { $0.isFileURL }
            .compactMap { url -> (path: String, uti: String)? in
                let path = url.path
                // Bỏ qua các file đặc biệt của macOS
                guard !path.hasSuffix("/") else { return nil }
                let uti = detectUTI(for: url)
                return (path, uti)
            }
    }

    /// Tạo security-scoped bookmark để truy cập file về sau (kể cả khi file di chuyển).
    static func createBookmark(for url: URL) -> Data? {
        try? url.bookmarkData(
            options: .withSecurityScope,
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        )
    }

    /// Lấy kích thước hiển thị của file (dạng string).
    static func formattedFileSize(at path: String) -> String {
        guard let attrs = try? FileManager.default.attributesOfItem(atPath: path),
              let size = attrs[.size] as? UInt64
        else { return "" }
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(size))
    }

    /// Xác định xem pasteboard hiện tại có chứa file hay không.
    static func hasFiles(in pasteboard: NSPasteboard) -> Bool {
        let fileTypes: [NSPasteboard.PasteboardType] = [
            .fileURL,
            NSPasteboard.PasteboardType("public.file-url")
        ]
        return pasteboard.availableType(from: fileTypes) != nil
    }

    // MARK: - Private

    /// Suy luận UTI từ URL (dùng UTType).
    private static func detectUTI(for url: URL) -> String {
        if let uti = try? url.resourceValues(forKeys: [.typeIdentifierKey]).typeIdentifier {
            return uti
        }
        // Fallback: suy luận từ extension
        let ext = url.pathExtension
        if let type = UTType(filenameExtension: ext) {
            return type.identifier
        }
        return "public.data"
    }

    /// Kiểm tra xem một UTI có thuộc nhóm ảnh không.
    static func isImageUTI(_ uti: String) -> Bool {
        guard let type = UTType(uti) else { return false }
        return type.conforms(to: .image)
    }
}
