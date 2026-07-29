import SwiftUI
import AppKit

/// Vùng cho phép kéo di chuyển cả cửa sổ panel (dùng cho cửa sổ không viền).
///
/// Cửa sổ `.borderless` không tự kéo được. NSView này bắt `mouseDown` và gọi
/// `window.performDrag(with:)` — API native để bắt đầu kéo cửa sổ, mượt và đúng
/// hành vi hệ thống (snap, đa màn hình...).
struct WindowDragArea: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView { DragView() }
    func updateNSView(_ nsView: NSView, context: Context) {}

    private final class DragView: NSView {
        override func mouseDown(with event: NSEvent) {
            window?.performDrag(with: event)
        }
        // Kéo bằng chuột phải/giữ cũng không cần; chỉ xử lý chuột trái ở trên.
        override var mouseDownCanMoveWindow: Bool { true }
    }
}
