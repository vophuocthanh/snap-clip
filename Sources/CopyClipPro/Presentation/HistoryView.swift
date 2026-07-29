import SwiftUI

/// Popover chính hiển thị clipboard history: ô tìm kiếm + danh sách + footer.
struct HistoryView: View {
    @ObservedObject var viewModel: HistoryViewModel

    /// Người dùng chọn một item (click hoặc Enter).
    var onSelect: (ClipboardItem) -> Void
    /// Đóng popover (Esc).
    var onClose: () -> Void
    /// Mở cửa sổ Settings.
    var onOpenSettings: () -> Void

    @FocusState private var searchFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            dragHandle
            searchBar
            Divider()
            content
            Divider()
            footer
        }
        .frame(width: 380, height: 480)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .onAppear { searchFocused = true }
    }

    // MARK: - Drag handle (kéo di chuyển panel)

    private var dragHandle: some View {
        ZStack {
            WindowDragArea() // toàn dải trên cùng kéo được
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
            Button {
                viewModel.onlyFavorites.toggle()
            } label: {
                Image(systemName: viewModel.onlyFavorites ? "star.fill" : "star")
                    .foregroundStyle(viewModel.onlyFavorites ? .yellow : .secondary)
            }
            .buttonStyle(.plain)
            .help("Chỉ hiện mục yêu thích")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
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
                            HistoryRow(
                                item: item,
                                isSelected: index == viewModel.selectedIndex
                            )
                            // Định danh theo item.id (KHÔNG theo index) để SwiftUI cập nhật
                            // đúng nội dung/ảnh khi danh sách thay đổi — tránh kẹt ảnh cũ.
                            .id(item.id)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                viewModel.selectedIndex = index
                                onSelect(item)
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
            Image(systemName: "doc.on.clipboard")
                .font(.system(size: 34))
                .foregroundStyle(.tertiary)
            Text(viewModel.searchText.isEmpty ? "Chưa có mục nào" : "Không tìm thấy kết quả")
                .foregroundStyle(.secondary)
            if viewModel.searchText.isEmpty {
                Text("Hãy copy nội dung bất kỳ để bắt đầu")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private func rowMenu(for item: ClipboardItem) -> some View {
        Button("Dán") { onSelect(item) }
        Button(item.isPinned ? "Bỏ ghim" : "Ghim") { viewModel.togglePin(item) }
        Button(item.isFavorite ? "Bỏ yêu thích" : "Yêu thích") { viewModel.toggleFavorite(item) }
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
