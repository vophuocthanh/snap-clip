import AppKit
import Carbon.HIToolbox

/// Chịu trách nhiệm đưa một item trở lại pasteboard và (tuỳ chọn) tự động paste
/// vào ứng dụng đang active.
@MainActor
final class PasteService {
    private let pasteboard: NSPasteboard
    /// Được gọi trước khi ghi để monitor biết bỏ qua thay đổi này.
    var willWriteToPasteboard: (() -> Void)?

    init(pasteboard: NSPasteboard = .general) {
        self.pasteboard = pasteboard
    }

    /// Chỉ copy nội dung item vào clipboard (không tự paste).
    /// Với item ảnh, `imageData` cần được nạp trước (từ repository).
    func copyToPasteboard(_ item: ClipboardItem) {
        pasteboard.clearContents()
        if item.type == .image, let data = item.imageData {
            pasteboard.setData(data, forType: .png)
        } else {
            pasteboard.setString(item.content, forType: .string)
        }
        // Gọi SAU khi ghi để monitor ghi nhận đúng changeCount vừa tạo ra → không tự
        // re-capture lại chính nội dung app vừa paste (tránh nhân bản clipboard).
        willWriteToPasteboard?()
    }

    /// Copy rồi giả lập Cmd+V để dán vào app đang active.
    ///
    /// Cần quyền Accessibility để synthesize phím. Nếu chưa cấp, nội dung vẫn nằm
    /// trong clipboard để người dùng tự dán bằng Cmd+V.
    func pasteToActiveApp(_ item: ClipboardItem) {
        copyToPasteboard(item)
        guard AXIsProcessTrusted() else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            Self.simulateCommandV()
        }
    }

    private static func simulateCommandV() {
        let source = CGEventSource(stateID: .combinedSessionState)
        let vKey = CGKeyCode(kVK_ANSI_V)

        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: vKey, keyDown: true)
        keyDown?.flags = .maskCommand
        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: vKey, keyDown: false)
        keyUp?.flags = .maskCommand

        keyDown?.post(tap: .cgAnnotatedSessionEventTap)
        keyUp?.post(tap: .cgAnnotatedSessionEventTap)
    }
}
