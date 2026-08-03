import AppKit

/// Panel nổi không viền dùng làm cửa sổ chính của menu bar app, thay cho NSPopover.
///
/// Vì sao không dùng NSPopover? Popover luôn ghim mũi tên sát nút status item nên
/// không thể tạo khoảng hở với menu bar (bị "cấn"). Một panel tự vẽ cho ta toàn
/// quyền định vị (đặt dưới menu bar với gap tuỳ ý) và bo góc/đổ bóng như Raycast.
///
/// Chỉ dùng styleMask tối thiểu ([.borderless]) — các tổ hợp như .fullSizeContentView
/// hoặc .nonactivatingPanel kèm override canBecomeKey có thể gây treo khi khởi tạo.
final class FloatingPanel: NSPanel {
    /// Cho phép trở thành key window để TextField nhận được ký tự gõ.
    override var canBecomeKey: Bool { true }

    init(contentRect: NSRect) {
        super.init(
            contentRect: contentRect,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        level = .floating
        isReleasedWhenClosed = false   // panel tái sử dụng nhiều lần
        hidesOnDeactivate = false
        isOpaque = false
        backgroundColor = .clear
        hasShadow = true
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
    }
}
