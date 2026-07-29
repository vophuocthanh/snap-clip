import SwiftUI

/// Một dòng trong danh sách history.
struct HistoryRow: View {
    let item: ClipboardItem
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 10) {
            leadingIcon
                .frame(width: 28, height: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.preview)
                    .lineLimit(1)
                    .foregroundStyle(isSelected ? Color.white : .primary)
                if let app = item.sourceAppName {
                    Text(app)
                        .font(.caption2)
                        .foregroundStyle(isSelected ? Color.white.opacity(0.8) : .secondary)
                }
            }

            Spacer(minLength: 4)

            if item.isPinned {
                Image(systemName: "pin.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(isSelected ? Color.white : .orange)
            }
            if item.isFavorite {
                Image(systemName: "star.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(isSelected ? Color.white : .yellow)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isSelected ? Color.accentColor : Color.clear)
        )
    }

    /// Icon dẫn đầu: thumbnail nếu là ảnh, ngược lại là SF Symbol theo loại.
    @ViewBuilder
    private var leadingIcon: some View {
        if item.type == .image,
           let data = item.thumbnailData,
           let nsImage = NSImage(data: data) {
            Image(nsImage: nsImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 28, height: 20)
                .clipShape(RoundedRectangle(cornerRadius: 3))
        } else {
            Image(systemName: item.type.symbolName)
                .font(.system(size: 13))
                .foregroundStyle(isSelected ? Color.white : .secondary)
        }
    }
}
