import AppKit

/// Tiện ích xử lý Rich Text (RTF/RTFD) từ pasteboard.
enum RichTextUtils {
    /// Đọc dữ liệu RTF từ pasteboard.
    /// - Returns: Tuple (plainText, rtfData) hoặc nil nếu pasteboard không có RTF.
    static func readRTF(from pasteboard: NSPasteboard) -> (plainText: String, rtfData: Data)? {
        // Ưu tiên RTFD (có thể chứa ảnh đính kèm)
        if let rtfd = pasteboard.data(forType: .rtfd),
           let plain = plainTextFromRTF(rtfd) {
            return (plain, rtfd)
        }
        // RTF thường
        if let rtf = pasteboard.data(forType: .rtf),
           let plain = plainTextFromRTF(rtf) {
            return (plain, rtf)
        }
        return nil
    }

    /// Kiểm tra pasteboard có RTF hay không (không đọc dữ liệu).
    static func hasRTF(in pasteboard: NSPasteboard) -> Bool {
        pasteboard.availableType(from: [.rtf, .rtfd]) != nil
    }

    /// Render NSAttributedString từ dữ liệu RTF.
    static func attributedString(from rtfData: Data) -> NSAttributedString? {
        NSAttributedString(rtf: rtfData, documentAttributes: nil)
    }

    /// Chuyển RTF data → plain text.
    static func plainTextFromRTF(_ data: Data) -> String? {
        guard let attr = attributedString(from: data) else { return nil }
        return attr.string
    }
}
