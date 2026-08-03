import Foundation
import CryptoKit
import os

/// Config for user, stored in UserDefaults (lightweight, sync with system).
@MainActor
final class AppSettings: ObservableObject {
    private let defaults: UserDefaults
    private let log = Logger(subsystem: "com.copyclippro", category: "settings")

    @Published var maxHistoryItems: Int {
        didSet { defaults.set(maxHistoryItems, forKey: Keys.maxHistoryItems) }
    }

    @Published var ignoreConcealed: Bool {
        didSet { defaults.set(ignoreConcealed, forKey: Keys.ignoreConcealed) }
    }

    @Published var pasteOnSelect: Bool {
        didSet { defaults.set(pasteOnSelect, forKey: Keys.pasteOnSelect) }
    }

    @Published var ignoredBundleIdsRaw: String {
        didSet { defaults.set(ignoredBundleIdsRaw, forKey: Keys.ignoredBundleIds) }
    }

    /// Mã hoá nội dung nhạy cảm trong DB bằng AES-GCM (CryptoKit).
    @Published var encryptSensitiveContent: Bool {
        didSet {
            defaults.set(encryptSensitiveContent, forKey: Keys.encryptSensitiveContent)
            if encryptSensitiveContent { ensureEncryptionKey() }
        }
    }

    var ignoredBundleIds: Set<String> {
        Set(
            ignoredBundleIdsRaw
                .split(separator: ",")
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }
        )
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.maxHistoryItems = defaults.object(forKey: Keys.maxHistoryItems) as? Int ?? 1000
        self.ignoreConcealed = defaults.object(forKey: Keys.ignoreConcealed) as? Bool ?? true
        self.pasteOnSelect = defaults.object(forKey: Keys.pasteOnSelect) as? Bool ?? true
        self.ignoredBundleIdsRaw = defaults.string(forKey: Keys.ignoredBundleIds)
            ?? "com.apple.keychainaccess"
        self.encryptSensitiveContent = defaults.object(forKey: Keys.encryptSensitiveContent) as? Bool ?? false
        if encryptSensitiveContent { ensureEncryptionKey() }
    }

    // MARK: - Encryption

    /// Key mã hoá lưu trong Keychain (không bao giờ ghi xuống UserDefaults).
    private static let keyTag = "com.copyclippro.encryptionKey"

    /// Lấy hoặc tạo key AES-GCM 256-bit lưu trong Keychain.
    func encryptionKey() -> SymmetricKey? {
        guard encryptSensitiveContent else { return nil }
        return Self.loadOrCreateKey()
    }

    private func ensureEncryptionKey() {
        _ = Self.loadOrCreateKey()
    }

    private static func loadOrCreateKey() -> SymmetricKey? {
        // Thử đọc key từ Keychain
        let query: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: keyTag,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        if status == errSecSuccess, let data = item as? Data {
            return SymmetricKey(data: data)
        }
        // Tạo key mới
        let key = SymmetricKey(size: .bits256)
        let keyData = key.withUnsafeBytes { Data($0) }
        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: keyTag,
            kSecValueData as String: keyData,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
        ]
        let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
        if addStatus != errSecSuccess {
            Logger(subsystem: "com.copyclippro", category: "settings")
                .error("Failed to store encryption key: \(addStatus)")
            return nil
        }
        Logger(subsystem: "com.copyclippro", category: "settings")
            .info("Created new encryption key")
        return key
    }

    private enum Keys {
        static let maxHistoryItems = "maxHistoryItems"
        static let ignoreConcealed = "ignoreConcealed"
        static let pasteOnSelect = "pasteOnSelect"
        static let ignoredBundleIds = "ignoredBundleIds"
        static let encryptSensitiveContent = "encryptSensitiveContent"
    }
}
