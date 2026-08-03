import Foundation
import Combine
import os

/// ViewModel for history list (MVVM).
@MainActor
final class HistoryViewModel: ObservableObject {
    @Published private(set) var items: [ClipboardItem] = []
    @Published var searchText: String = "" {
        didSet { scheduleReload() }
    }
    @Published var onlyFavorites: Bool = false {
        didSet { reload() }
    }
    @Published var onlySnippets: Bool = false {
        didSet { reload() }
    }
    @Published var selectedTag: String = "" {
        didSet { reload() }
    }
    @Published private(set) var availableTags: [String] = []
    @Published var selectedIndex: Int = 0
    @Published private(set) var errorMessage: String?

    private let repository: ClipboardRepository
    private var reloadTask: Task<Void, Never>?
    private let log = Logger(subsystem: "com.copyclippro", category: "viewmodel")

    init(repository: ClipboardRepository) {
        self.repository = repository
        reload()
    }

    private func scheduleReload() {
        reloadTask?.cancel()
        reloadTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 120_000_000)
            guard !Task.isCancelled else { return }
            self?.reload()
        }
    }

    func reload() {
        let query = HistoryQuery(
            searchText: searchText,
            onlyFavorites: onlyFavorites,
            onlySnippets: onlySnippets,
            tag: selectedTag
        )
        do {
            items = try repository.fetch(query)
            if selectedIndex >= items.count { selectedIndex = max(0, items.count - 1) }
            availableTags = try repository.allTags()
            errorMessage = nil
        } catch {
            errorMessage = "Failed to load history: \(error)"
            log.error("reload failed: \(error)")
        }
    }

    // MARK: - Mutations

    func togglePin(_ item: ClipboardItem) {
        try? repository.setPinned(!item.isPinned, id: item.id)
        reload()
    }

    func toggleFavorite(_ item: ClipboardItem) {
        try? repository.setFavorite(!item.isFavorite, id: item.id)
        reload()
    }

    func delete(_ item: ClipboardItem) {
        try? repository.delete(id: item.id)
        reload()
    }

    func clearHistory(keepProtected: Bool = true) {
        try? repository.clear(keepProtected: keepProtected)
        reload()
    }

    // MARK: - Snippets

    func createSnippet(content: String, tags: String) {
        guard !content.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        do {
            try repository.createSnippet(content: content, tags: tags)
            reload()
        } catch {
            errorMessage = "Failed to create snippet: \(error)"
            log.error("createSnippet failed: \(error)")
        }
    }

    func updateTags(_ tags: String, for item: ClipboardItem) {
        try? repository.updateTags(tags, id: item.id)
        reload()
    }

    // MARK: - Keyboard Navigation

    var selectedItem: ClipboardItem? {
        guard items.indices.contains(selectedIndex) else { return nil }
        return items[selectedIndex]
    }

    func moveSelection(by delta: Int) {
        guard !items.isEmpty else { return }
        selectedIndex = min(max(0, selectedIndex + delta), items.count - 1)
    }

    // MARK: - Detail View

    func loadFullContent(for item: ClipboardItem) async -> ClipboardItem {
        var loaded = item
        switch item.type {
        case .image:
            loaded.imageData = try? repository.imageData(id: item.id)
        case .richText:
            loaded.richTextData = try? repository.richTextData(id: item.id)
        case .file:
            if let url = try? repository.resolveFileURL(id: item.id) {
                loaded.filePath = url.path
                loaded.fileBookmark = FileUtils.createBookmark(for: url)
            }
        default:
            break
        }
        return loaded
    }
}
