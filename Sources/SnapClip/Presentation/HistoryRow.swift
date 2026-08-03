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
                Text(item.subtitle)
                    .font(.caption2)
                    .lineLimit(1)
                    .foregroundStyle(isSelected ? Color.white.opacity(0.7) : .secondary)
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

    /// Icon dẫn đầu theo loại nội dung.
    @ViewBuilder
    private var leadingIcon: some View {
        switch item.type {
        case .image:
            imageThumbnail
        case .color:
            colorSwatch
        case .file:
            fileIconView
        default:
            defaultIcon
        }
    }

    /// Thumbnail ảnh.
    @ViewBuilder
    private var imageThumbnail: some View {
        if let data = item.thumbnailData,
           let nsImage = NSImage(data: data) {
            Image(nsImage: nsImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 28, height: 20)
                .clipShape(RoundedRectangle(cornerRadius: 3))
        } else {
            defaultIcon
        }
    }

    /// Swatch màu.
    private var colorSwatch: some View {
        Circle()
            .fill(Color.fromHexOrName(item.content))
            .frame(width: 16, height: 16)
            .overlay(
                Circle()
                    .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
            )
    }

    /// Icon file từ NSWorkspace.
    @ViewBuilder
    private var fileIconView: some View {
        if let path = item.filePath {
            let icon = NSWorkspace.shared.icon(forFile: path)
            Image(nsImage: icon)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 20, height: 20)
        } else {
            defaultIcon
        }
    }

    /// SF Symbol mặc định.
    private var defaultIcon: some View {
        Image(systemName: item.type.symbolName)
            .font(.system(size: 13))
            .foregroundStyle(isSelected ? Color.white : .secondary)
    }
}

// MARK: - Color Helper

private extension Color {
    /// Parse màu từ hex string hoặc tên màu cơ bản.
    static func fromHexOrName(_ string: String) -> Color {
        let s = string.trimmingCharacters(in: .whitespaces)
        // Hex
        if s.hasPrefix("#") {
            let hex = s.dropFirst()
            if let value = Int(hex, radix: 16) {
                let r = Double((value >> 16) & 0xFF) / 255
                let g = Double((value >> 8) & 0xFF) / 255
                let b = Double(value & 0xFF) / 255
                return Color(red: r, green: g, blue: b)
            }
        }
        // rgb()
        let lower = s.lowercased().filter { !$0.isWhitespace }
        if lower.hasPrefix("rgb") {
            let nums = lower
                .replacingOccurrences(of: "rgba(", with: "")
                .replacingOccurrences(of: "rgb(", with: "")
                .replacingOccurrences(of: ")", with: "")
                .split(separator: ",")
                .compactMap { Double($0) }
            if nums.count >= 3 {
                return Color(red: nums[0] / 255, green: nums[1] / 255, blue: nums[2] / 255)
            }
        }
        // Tên màu
        switch lower {
        case "red": return .red
        case "green": return .green
        case "blue": return .blue
        case "yellow": return .yellow
        case "orange": return .orange
        case "purple": return .purple
        case "pink": return .pink
        case "brown": return .brown
        case "black": return .black
        case "white": return .white
        case "gray", "grey": return .gray
        case "cyan": return .cyan
        case "magenta": return Color(red: 1, green: 0, blue: 1)
        default: return .gray
        }
    }
}
