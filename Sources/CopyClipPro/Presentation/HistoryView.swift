import SwiftUI

/// Popover chính hiển thị clipboard history.
struct HistoryView: View {
    @ObservedObject var viewModel: HistoryViewModel

    var onSelect: (ClipboardItem) -> Void
    var onClose: () -> Void
    var onOpenSettings: () -> Void
    var onShowDetail: (ClipboardItem) -> Void

    @FocusState private var searchFocused: Bool
    @State private var showSnippetSheet = false
    @State private var snippetContent = ""
    @State private var snippetTags = ""

    var body: some View {
        VStack(spacing: 0) {
            dragHandle
            searchBar
            filterBar
            Divider()
            content
            Divider()
            footer
        }
        .frame(width: 380, height: 480)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .onAppear { searchFocused = true }
        .sheet(isPresented: $showSnippetSheet) { createSnippetSheet }
    }

    // MARK: - Drag handle

    private var dragHandle: some View {
        ZStack {
            WindowDragArea()
            Capsule()
                .fill(Color.secondary.opacity(0.35))
                .frame(width: 40, height: 5)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 18)
        .contentShape(Rectangle())
    }

    // MARK: - Search

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Tìm kiếm…", text: $viewModel.searchText)
                .textFieldStyle(.plain)
                .focused($searchFocused)
                .onSubmit { selectCurrent() }
            if !viewModel.searchText.isEmpty {
                Button {
                    viewModel.searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            filterButtons
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    // MARK: - Filter buttons

    private var filterButtons: some View {
        HStack(spacing: 4) {
            Button {
                viewModel.onlyFavorites.toggle()
            } label: {
                Image(systemName: viewModel.onlyFavorites ? "star.fill" : "star")
                    .foregroundStyle(viewModel.onlyFavorites ? .yellow : .secondary)
            }
            .buttonStyle(.plain)
            .help("Chỉ hiện mục yêu thích")

            Button {
                viewModel.onlySnippets.toggle()
            } label: {
                Image(systemName: viewModel.onlySnippets ? "square.and.pencil.fill" : "square.and.pencil")
                    .foregroundStyle(viewModel.onlySnippets ? Color.accentColor : .secondary)
            }
            .buttonStyle(.plain)
            .help("Chỉ hiện snippet")

            Button {
                showSnippetSheet = true
            } label: {
                Image(systemName: "plus.circle")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .help("Tạo snippet mới")
        }
    }

    // MARK: - Tag filter

    @ViewBuilder
    private var filterBar: some View {
        if !viewModel.availableTags.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    Button("Tất cả") {
                        viewModel.selectedTag = ""
                    }
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(viewModel.selectedTag.isEmpty ? Color.accentColor.opacity(0.2) : Color.clear)
                    .clipShape(Capsule())

                    ForEach(viewModel.availableTags, id: \.self) { tag in
                        Button(tag) {
                            viewModel.selectedTag = (viewModel.selectedTag == tag) ? "" : tag
                        }
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(viewModel.selectedTag == tag ? Color.accentColor.opacity(0.2) : Color.clear)
                        .clipShape(Capsule())
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
            }
        }
    }

    // MARK: - Create Snippet Sheet

    private var createSnippetSheet: some View {
        VStack(spacing: 16) {
            Text("Tạo Snippet mới")
                .font(.headline)

            TextEditor(text: $snippetContent)
                .font(.body)
                .frame(height: 120)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                )

            TextField("Tag (cách nhau bằng phẩy)", text: $snippetTags)
                .textFieldStyle(.roundedBorder)

            HStack(spacing: 12) {
                Button("Huỷ") {
                    showSnippetSheet = false
                    snippetContent = ""
                    snippetTags = ""
                }
                Button("Lưu") {
                    viewModel.createSnippet(content: snippetContent, tags: snippetTags)
                    showSnippetSheet = false
                    snippetContent = ""
                    snippetTags = ""
                }
                .buttonStyle(.borderedProminent)
                .disabled(snippetContent.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(20)
        .frame(width: 320, height: 260)
    }

    // MARK: - List

    @ViewBuilder
    private var content: some View {
        if viewModel.items.isEmpty {
            emptyState
        } else {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 2) {
                        ForEach(Array(viewModel.items.enumerated()), id: \.element.id) { index, item in
                            HStack(spacing: 2) {
                                let isSelected = index == viewModel.selectedIndex
                                HistoryRow(item: item, isSelected: isSelected)
                                    .id(item.id)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        viewModel.selectedIndex = index
                                        onSelect(item)
                                    }
                                Button {
                                    onShowDetail(item)
                                } label: {
                                    Image(systemName: "info.circle")
                                        .font(.caption)
                                        .foregroundStyle(isSelected ? Color.white : Color.secondary.opacity(0.4))
                                }
                                .buttonStyle(.plain)
                                .help("Xem chi tiết")
                                .padding(.trailing, 6)
                            }
                            .contextMenu { rowMenu(for: item) }
                        }
                    }
                    .padding(.vertical, 4)
                    .padding(.horizontal, 6)
                }
                .onChange(of: viewModel.selectedIndex) { _, newValue in
                    guard viewModel.items.indices.contains(newValue) else { return }
                    withAnimation(.easeOut(duration: 0.12)) {
                        proxy.scrollTo(viewModel.items[newValue].id, anchor: .center)
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: viewModel.onlySnippets ? "square.and.pencil" : "doc.on.clipboard")
                .font(.system(size: 34))
                .foregroundStyle(.tertiary)
            Text(viewModel.searchText.isEmpty ? "Chưa có mục nào" : "Không tìm thấy kết quả")
                .foregroundStyle(.secondary)
            if viewModel.searchText.isEmpty {
                Text(viewModel.onlySnippets
                     ? "Nhấn + để tạo snippet mới"
                     : "Hãy copy nội dung bất kỳ để bắt đầu")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private func rowMenu(for item: ClipboardItem) -> some View {
        Button("Dán") { onSelect(item) }
        Button("Xem chi tiết") { onShowDetail(item) }
        Divider()
        Button(item.isPinned ? "Bỏ ghim" : "Ghim") { viewModel.togglePin(item) }
        Button(item.isFavorite ? "Bỏ yêu thích" : "Yêu thích") { viewModel.toggleFavorite(item) }
        if !item.tags.isEmpty {
            Menu("Tag: \(item.tags)") {
                ForEach(viewModel.availableTags, id: \.self) { tag in
                    Button(tag) { viewModel.updateTags(tag, for: item) }
                }
                Button("Xoá tag", role: .destructive) { viewModel.updateTags("", for: item) }
            }
        }
        Divider()
        Button("Xoá", role: .destructive) { viewModel.delete(item) }
    }

    // MARK: - Footer

    private var footer: some View {
        HStack(spacing: 12) {
            Text("\(viewModel.items.count) mục")
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Button {
                viewModel.clearHistory(keepProtected: true)
            } label: {
                Image(systemName: "trash")
            }
            .buttonStyle(.plain)
            .help("Xoá lịch sử (giữ mục đã ghim/yêu thích)")

            Button {
                onOpenSettings()
            } label: {
                Image(systemName: "gearshape")
            }
            .buttonStyle(.plain)
            .help("Cài đặt")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private func selectCurrent() {
        if let item = viewModel.selectedItem {
            onSelect(item)
        }
    }
}
