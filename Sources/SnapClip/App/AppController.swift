import AppKit
import SwiftUI
import Carbon.HIToolbox
import os

// Main App

@MainActor
final class AppController: NSObject, NSApplicationDelegate, NSWindowDelegate {
    // Infrastructure
    private var repository: ClipboardRepository!
    private var monitor: ClipboardMonitor!
    private var pasteService: PasteService!
    private var hotkey: GlobalHotkey?

    // Application / Presentation
    private let settings = AppSettings()
    private var historyVM: HistoryViewModel!

    // UI
    private var statusItem: NSStatusItem!
    private var panel: FloatingPanel!
    private var settingsWindow: NSWindow?
    private var detailWindow: NSWindow?
    private var keyMonitor: Any?
    private var panelDismissedAt: Date?

    private let log = Logger(subsystem: "com.snapclip", category: "app")

    func applicationDidFinishLaunching(_ notification: Notification) {
        log.info("App started")
        NSApp.setActivationPolicy(.regular)

        do {
            repository = try SQLiteClipboardRepository.makeDefault()
        } catch {
            presentFatal("Failed to initialize database:\n\(error)")
            return
        }

        historyVM = HistoryViewModel(repository: repository)
        pasteService = PasteService()
        pasteService.willWriteToPasteboard = { [weak self] in
            self?.monitor.markSelfWrite()
        }

        setupMonitor()
        setupStatusItem()
        setupPanel()
        setupHotkey()
    }

    // Click on the Dock icon (regular app, no window) → open the history panel.
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if panel?.isVisible != true {
            showPopover()
        }
        return true
    }

    // MARK: - Monitor

    private func setupMonitor() {
        monitor = ClipboardMonitor()
        monitor.ignoreConcealed = settings.ignoreConcealed
        monitor.ignoredBundleIds = settings.ignoredBundleIds
        monitor.onNewItem = { [weak self] item in
            guard let self else { return }
            _ = try? self.repository.insert(item)
            try? self.repository.enforceRetention(maxItems: self.settings.maxHistoryItems)
            self.historyVM.reload()
        }
        monitor.start()
    }

    // MARK: - Status item

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.isVisible = true
        guard let button = statusItem.button else {
            NSLog("[SNC] setupStatusItem: button == nil")
            return
        }

        // Use emoji as label: color, prominent, easy to spot on the menu bar with many icons.
        button.title = "📋"
        button.imagePosition = .noImage
        button.toolTip = "SnapClip — lịch sử clipboard (\(currentHotkeyLabel))"
        button.action = #selector(statusItemClicked(_:))
        button.target = self
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
    }

    @objc private func statusItemClicked(_ sender: NSStatusBarButton) {
        let event = NSApp.currentEvent
        let isSecondary = event?.type == .rightMouseUp
            || event?.modifierFlags.contains(.control) == true
        // Hoãn ra khỏi vòng theo dõi chuột của status bar (NSControlTrackMouse) trước
        // khi thao tác cửa sổ — tránh crash/nháy khi activate/makeKey trong lúc tracking.
        DispatchQueue.main.async { [weak self] in
            if isSecondary {
                self?.showContextMenu()
            } else {
                self?.togglePopover()
            }
        }
    }

    private func showContextMenu() {
        let menu = NSMenu()
        menu.addItem(withTitle: "Mở SnapClip", action: #selector(togglePopover), keyEquivalent: "")
        menu.addItem(withTitle: "Cài đặt…", action: #selector(openSettings), keyEquivalent: ",")
        menu.addItem(.separator())
        menu.addItem(withTitle: "Thoát", action: #selector(quit), keyEquivalent: "q")
        for item in menu.items { item.target = self }
        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        statusItem.menu = nil // trả lại hành vi click-toggle sau khi menu đóng
    }

    // MARK: - Panel

    /// Khoảng hở giữa menu bar và panel (điều chỉnh ở đây nếu muốn cao/thấp hơn).
    private let panelGap: CGFloat = 8
    private let panelSize = NSSize(width: 380, height: 480)

    private func setupPanel() {
        panel = FloatingPanel(contentRect: NSRect(origin: .zero, size: panelSize))
        panel.delegate = self

        let root = HistoryView(
            viewModel: historyVM,
            onSelect: { [weak self] item in self?.handleSelect(item) },
            onClose: { [weak self] in self?.closePopover() },
            onOpenSettings: { [weak self] in self?.openSettings() },
            onShowDetail: { [weak self] item in self?.showDetail(item) }
        )
        let hosting = NSHostingView(rootView: root)
        hosting.wantsLayer = true
        hosting.layer?.cornerRadius = 12
        hosting.layer?.masksToBounds = true
        panel.contentView = hosting
    }

    @objc private func togglePopover() {
        guard let panel else { NSLog("[SNC] togglePopover: panel == nil"); return }
        if panel.isVisible {
            closePopover()
        } else {
            // Chặn mở lại ngay sau khi click nút status làm panel resign key & đóng.
            if let closedAt = panelDismissedAt, Date().timeIntervalSince(closedAt) < 0.15 {
                return
            }
            showPopover()
        }
    }

    private func showPopover() {
        guard let panel else { NSLog("[SNC] showPopover: panel == nil"); return }
        guard let historyVM else { NSLog("[SNC] showPopover: historyVM == nil"); return }
        historyVM.selectedIndex = 0
        historyVM.reload()

        // Mở panel trên MÀN HÌNH ĐANG CÓ CON TRỎ CHUỘT (nơi người dùng đang thao tác).
        // Không bám vào nút status vì trong setup nhiều màn hình, nút có thể nằm ở màn
        // hình khác → panel sẽ hiện đúng nơi bạn đang nhìn.
        let mouse = NSEvent.mouseLocation
        let activeScreen = NSScreen.screens.first { NSMouseInRect(mouse, $0.frame, false) }
            ?? NSScreen.main
            ?? NSScreen.screens.first
        guard let screen = activeScreen else { NSLog("[SNC] showPopover: no screen"); return }
        let vf = screen.visibleFrame

        var origin: NSPoint
        if let button = statusItem?.button,
           let win = button.window, win.screen == screen {
            // Nút status ở cùng màn hình active → thả panel ngay dưới nút.
            let r = win.convertToScreen(button.convert(button.bounds, to: nil))
            origin = NSPoint(x: r.midX - panelSize.width / 2,
                             y: r.minY - panelGap - panelSize.height)
        } else {
            // Nút ở màn hình khác → canh theo X của chuột, ngay dưới menu bar màn hình active.
            origin = NSPoint(x: mouse.x - panelSize.width / 2,
                             y: vf.maxY - panelGap - panelSize.height)
        }
        // Giữ panel nằm gọn trong vùng hiển thị của màn hình active.
        origin.x = min(max(vf.minX + 8, origin.x), vf.maxX - panelSize.width - 8)
        origin.y = min(max(vf.minY + 8, origin.y), vf.maxY - panelSize.height - 8)

        panel.setFrame(NSRect(origin: origin, size: panelSize), display: true)
        panel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        installKeyMonitor()
    }

    private func closePopover() {
        guard let panel, panel.isVisible else { return }
        panel.orderOut(nil)
        panelDismissedAt = Date()
        removeKeyMonitor()
    }

    /// Đóng panel khi mất focus (click ra ngoài / chuyển app).
    func windowDidResignKey(_ notification: Notification) {
        closePopover()
    }

    private func handleSelect(_ item: ClipboardItem) {
        closePopover()

        // Với ảnh, item trong danh sách chỉ có thumbnail → nạp ảnh gốc để paste đúng chất lượng.
        var resolved = item
        if item.type == .image, item.imageData == nil {
            resolved.imageData = try? repository.imageData(id: item.id)
        }

        if settings.pasteOnSelect {
            pasteService.pasteToActiveApp(resolved)
        } else {
            pasteService.copyToPasteboard(resolved)
        }
    }

    // MARK: - Detail View

    private func showDetail(_ item: ClipboardItem) {
        closePopover()
        if let win = detailWindow {
            win.close()
            detailWindow = nil
        }

        let view = DetailView(
            item: item,
            onLoadFullContent: { [weak self] item in
                await self?.historyVM.loadFullContent(for: item) ?? item
            },
            onCopy: { [weak self] item in
                var resolved = item
                if item.type == .image, item.imageData == nil {
                    resolved.imageData = try? self?.repository.imageData(id: item.id)
                }
                if item.type == .richText, item.richTextData == nil {
                    resolved.richTextData = try? self?.repository.richTextData(id: item.id)
                }
                self?.pasteService.copyToPasteboard(resolved)
            },
            onClose: { [weak self] in
                self?.detailWindow?.close()
                self?.detailWindow = nil
            }
        )

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 520),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Chi tiết"
        window.contentViewController = NSHostingController(rootView: view)
        window.center()
        window.isReleasedWhenClosed = false
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        detailWindow = window
    }

    // MARK: - Keyboard navigation trong popover

    private func installKeyMonitor() {
        removeKeyMonitor()
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self, self.panel?.isVisible == true else { return event }
            switch Int(event.keyCode) {
            case kVK_DownArrow:
                self.historyVM.moveSelection(by: 1)
                return nil
            case kVK_UpArrow:
                self.historyVM.moveSelection(by: -1)
                return nil
            case kVK_Return, kVK_ANSI_KeypadEnter:
                if let item = self.historyVM.selectedItem {
                    self.handleSelect(item)
                }
                return nil
            case kVK_Escape:
                self.closePopover()
                return nil
            case kVK_ANSI_I:
                // Cmd+I: mở chi tiết mục đang chọn
                if event.modifierFlags.contains(.command),
                   let item = self.historyVM.selectedItem {
                    self.showDetail(item)
                    return nil
                }
                return event
            default:
                // Cmd+Delete: xoá mục đang chọn.
                if event.modifierFlags.contains(.command),
                   Int(event.keyCode) == kVK_Delete,
                   let item = self.historyVM.selectedItem {
                    self.historyVM.delete(item)
                    return nil
                }
                return event
            }
        }
    }

    private func removeKeyMonitor() {
        if let keyMonitor {
            NSEvent.removeMonitor(keyMonitor)
            self.keyMonitor = nil
        }
    }

    // MARK: - Hotkey

    /// Nhãn của combo hotkey đang hoạt động (để hiện trong tooltip).
    private var currentHotkeyLabel = "—"

    private func setupHotkey() {
        // Thử lần lượt các combo ưu tiên tới khi đăng ký được. RegisterEventHotKey sẽ
        // THẤT BẠI nếu combo đã bị app khác chiếm (vd Raycast giữ ⌘⇧V) → thử combo kế.
        let candidates: [(label: String, mods: Int)] = [
            ("⌘⌥V", cmdKey | optionKey),
            ("⌃⌥⌘V", controlKey | optionKey | cmdKey),
            ("⌃⌥V", controlKey | optionKey),
            ("⌘⌥C", cmdKey | optionKey) // (C) — chỉ dùng khi các combo V đều bận
        ]
        for c in candidates {
            let keyCode = c.label.hasSuffix("C") ? kVK_ANSI_C : kVK_ANSI_V
            if let hk = GlobalHotkey(
                keyCode: UInt32(keyCode),
                modifiers: UInt32(c.mods),
                handler: { [weak self] in self?.togglePopover() }
            ) {
                hotkey = hk
                currentHotkeyLabel = c.label
                statusItem?.button?.toolTip = "SnapClip — lịch sử clipboard (\(c.label))"
                return
            }
        }
        NSLog("[SNC] hotkey registration FAILED cho tất cả combo — chỉ mở được bằng click icon")
    }

    // MARK: - Settings window

    @objc private func openSettings() {
        closePopover()
        if let window = settingsWindow {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        let view = SettingsView(
            settings: settings,
            accessibilityGranted: AXIsProcessTrusted(),
            onRequestAccessibility: { Self.openAccessibilityPrefs() }
        )
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 460, height: 520),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Cài đặt SnapClip"
        window.contentViewController = NSHostingController(rootView: view)
        window.center()
        window.isReleasedWhenClosed = false
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        settingsWindow = window

        // Áp dụng lại cấu hình cho monitor khi đóng settings.
        NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification,
            object: window,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.applySettingsToMonitor() }
        }
    }

    private func applySettingsToMonitor() {
        monitor.ignoreConcealed = settings.ignoreConcealed
        monitor.ignoredBundleIds = settings.ignoredBundleIds
    }

    private static func openAccessibilityPrefs() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)
    }

    // MARK: - Lifecycle

    @objc private func quit() {
        log.info("App terminating")
        NSApp.terminate(nil)
    }

    private func presentFatal(_ message: String) {
        log.error("Fatal error: \(message)")
        let alert = NSAlert()
        alert.messageText = "SnapClip"
        alert.informativeText = message
        alert.alertStyle = .critical
        alert.runModal()
        NSApp.terminate(nil)
    }
}
