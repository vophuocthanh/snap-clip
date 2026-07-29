import AppKit
import Carbon.HIToolbox

/// Đăng ký một global hotkey (hoạt động toàn hệ thống) bằng Carbon Event Manager.
///
/// Vì sao Carbon mà không phải API mới hơn? macOS vẫn chưa có API Swift/Cocoa
/// công khai cho global hotkey; `RegisterEventHotKey` của Carbon là cách chính
/// thức, ổn định, KHÔNG cần quyền Accessibility (khác với CGEventTap). Đây là
/// lựa chọn zero-dependency, nhẹ và tin cậy nhất.
final class GlobalHotkey {
    private var hotKeyRef: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?
    private let handler: () -> Void

    /// - Parameters:
    ///   - keyCode: mã phím ảo (vd `kVK_ANSI_V`).
    ///   - modifiers: tổ hợp Carbon modifier (vd `cmdKey | shiftKey`).
    init?(keyCode: UInt32, modifiers: UInt32, handler: @escaping () -> Void) {
        self.handler = handler

        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        // Truyền `self` sang callback C qua userData.
        let selfPtr = Unmanaged.passUnretained(self).toOpaque()
        let installStatus = InstallEventHandler(
            GetEventDispatcherTarget(),
            { _, event, userData -> OSStatus in
                guard let userData else { return noErr }
                let instance = Unmanaged<GlobalHotkey>.fromOpaque(userData).takeUnretainedValue()
                var hkID = EventHotKeyID()
                GetEventParameter(
                    event,
                    EventParamName(kEventParamDirectObject),
                    EventParamType(typeEventHotKeyID),
                    nil,
                    MemoryLayout<EventHotKeyID>.size,
                    nil,
                    &hkID
                )
                DispatchQueue.main.async { instance.handler() }
                return noErr
            },
            1,
            &eventType,
            selfPtr,
            &eventHandler
        )
        guard installStatus == noErr else { return nil }

        let hotKeyID = EventHotKeyID(
            signature: OSType(0x43_43_50_52), // 'CCPR'
            id: 1
        )
        let registerStatus = RegisterEventHotKey(
            keyCode,
            modifiers,
            hotKeyID,
            GetEventDispatcherTarget(),
            0,
            &hotKeyRef
        )
        guard registerStatus == noErr else { return nil }
    }

    deinit {
        if let hotKeyRef { UnregisterEventHotKey(hotKeyRef) }
        if let eventHandler { RemoveEventHandler(eventHandler) }
    }
}
