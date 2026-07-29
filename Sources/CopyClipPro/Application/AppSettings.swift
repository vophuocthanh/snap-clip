import Foundation

/// Config for user, stored in UserDefaults (lightweight, sync with system).
@MainActor
final class AppSettings: ObservableObject {
    private let defaults: UserDefaults

    /// Number of items to keep in history (not including pinned/favorite).
    @Published var maxHistoryItems: Int {
        didSet { defaults.set(maxHistoryItems, forKey: Keys.maxHistoryItems) }
    }

    /// Ignore content marked as concealed (password/OTP) by source app.
    @Published var ignoreConcealed: Bool {
        didSet { defaults.set(ignoreConcealed, forKey: Keys.ignoreConcealed) }
    }

    /// Auto paste (Cmd+V) after selecting item.
    @Published var pasteOnSelect: Bool {
        didSet { defaults.set(pasteOnSelect, forKey: Keys.pasteOnSelect) }
    }

    /// List of bundle ids to ignore, separated by comma.
    @Published var ignoredBundleIdsRaw: String {
        didSet { defaults.set(ignoredBundleIdsRaw, forKey: Keys.ignoredBundleIds) }
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
    }

    private enum Keys {
        static let maxHistoryItems = "maxHistoryItems"
        static let ignoreConcealed = "ignoreConcealed"
        static let pasteOnSelect = "pasteOnSelect"
        static let ignoredBundleIds = "ignoredBundleIds"
    }
}
