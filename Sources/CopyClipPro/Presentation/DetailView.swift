import SwiftUI
import CoreImage.CIFilterBuiltins

/// Detail view hiển thị toàn bộ nội dung của một clipboard item.
/// Mở dưới dạng sheet từ HistoryView.
struct DetailView: View {
    let item: ClipboardItem
    let onLoadFullContent: ((ClipboardItem) async -> ClipboardItem)?
    let onCopy: (ClipboardItem) -> Void
    let onClose: () -> Void

    @State private var fullItem: ClipboardItem
    @State private var image: NSImage?
    @State private var attributedText: NSAttributedString?
    @State private var fileIcon: NSImage?
    @State private var qrImage: NSImage?

    init(
        item: ClipboardItem,
        onLoadFullContent: ((ClipboardItem) async -> ClipboardItem)? = nil,
        onCopy: @escaping (ClipboardItem) -> Void,
        onClose: @escaping () -> Void
    ) {
        self.item = item
        self.onLoadFullContent = onLoadFullContent
        self.onCopy = onCopy
        self.onClose = onClose
        _fullItem = State(initialValue: item)
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            contentArea
            Divider()
            footer
        }
        .frame(width: 480, height: 520)
        .background(.regularMaterial)
        .task { await loadContent() }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 8) {
            Image(systemName: item.type.symbolName)
                .foregroundStyle(.secondary)
            Text(title)
                .font(.headline)
                .lineLimit(1)
            Spacer()
            Button(action: onClose) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.secondary)
                    .font(.title3)
            }
            .buttonStyle(.plain)
            .keyboardShortcut(.escape)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var title: String {
        switch item.type {
        case .text: return "Văn bản"
        case .url: return "Liên kết"
        case .color: return "Màu sắc"
        case .image: return "Hình ảnh"
        case .file: return "Tập tin"
        case .richText: return "Văn bản định dạng"
        }
    }

    // MARK: - Content

    @ViewBuilder
    private var contentArea: some View {
        ScrollView {
            VStack(spacing: 16) {
                switch item.type {
                case .text:
                    textContentView
                case .url:
                    urlContentView
                case .color:
                    colorContentView
                case .image:
                    imageContentView
                case .file:
                    fileContentView
                case .richText:
                    richTextContentView
                }
            }
            .padding(16)
        }
    }

    // MARK: Text

    private var textContentView: some View {
        Text(item.content)
            .textSelection(.enabled)
            .font(.body)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: URL

    @ViewBuilder
    private var urlContentView: some View {
        if let url = URL(string: item.content),
           url.scheme?.hasPrefix("http") == true {
            VStack(spacing: 16) {
                Link(destination: url) {
                    HStack {
                        Image(systemName: "safari")
                        Text("Mở trong trình duyệt")
                    }
                }
                .buttonStyle(.borderedProminent)

                // QR code
                if let qrImage {
                    Image(nsImage: qrImage)
                        .resizable()
                        .interpolation(.none)
                        .frame(width: 200, height: 200)
                }

                Text(item.content)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
            }
        } else {
            Text(item.content)
                .textSelection(.enabled)
                .font(.body)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: Color

    private var colorContentView: some View {
        VStack(spacing: 16) {
            // Swatch
            RoundedRectangle(cornerRadius: 12)
                .fill(parsedColor)
                .frame(height: 120)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                )

            HStack(spacing: 12) {
                colorChip("#\(hexString)", color: parsedColor)
                if let rgb = rgbString {
                    colorChip(rgb, color: parsedColor)
                }
            }
        }
    }

    private func colorChip(_ label: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)
            Text(label)
                .font(.caption.monospaced())
                .textSelection(.enabled)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.secondary.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    private var parsedColor: Color {
        let s = item.content.trimmingCharacters(in: .whitespaces)
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
                return Color(
                    red: nums[0] / 255,
                    green: nums[1] / 255,
                    blue: nums[2] / 255
                )
            }
        }
        // Color name
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

    private var hexString: String {
        let s = item.content.trimmingCharacters(in: .whitespaces)
        if s.hasPrefix("#") { return String(s.dropFirst()).uppercased() }
        return s.uppercased()
    }

    private var rgbString: String? {
        guard let rgb = NSColor(parsedColor).usingColorSpace(.sRGB) else { return nil }
        return "rgb(\(Int(rgb.redComponent * 255)), \(Int(rgb.greenComponent * 255)), \(Int(rgb.blueComponent * 255)))"
    }

    // MARK: Image

    @ViewBuilder
    private var imageContentView: some View {
        if let image {
            VStack(spacing: 12) {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 320)
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                Text(item.content)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        } else {
            ProgressView("Đang tải ảnh…")
        }
    }

    // MARK: File

    @ViewBuilder
    private var fileContentView: some View {
        VStack(spacing: 16) {
            if let fileIcon {
                Image(nsImage: fileIcon)
                    .resizable()
                    .frame(width: 64, height: 64)
            } else {
                Image(systemName: "doc.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 4) {
                if let path = fullItem.filePath {
                    Text(URL(fileURLWithPath: path).lastPathComponent)
                        .font(.headline)
                }
                if let uti = fullItem.fileUTI {
                    Text(uti)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                if let path = fullItem.filePath {
                    let size = FileUtils.formattedFileSize(at: path)
                    if !size.isEmpty {
                        Text(size)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            if let path = fullItem.filePath {
                Button("Mở trong Finder") {
                    NSWorkspace.shared.selectFile(path, inFileViewerRootedAtPath: "")
                }
                .buttonStyle(.bordered)
            }
        }
    }

    // MARK: Rich Text

    @ViewBuilder
    private var richTextContentView: some View {
        if let attr = attributedText {
            VStack(spacing: 12) {
                RichTextDisplay(attributedString: attr)
                    .frame(maxWidth: .infinity, minHeight: 100)
                Divider()
                Text(item.content)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        } else {
            Text(item.content)
                .textSelection(.enabled)
                .font(.body)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Footer

    private var footer: some View {
        HStack(spacing: 8) {
            infoBadge(icon: item.type.symbolName, text: title)
            if let app = item.sourceAppName {
                infoBadge(icon: "app", text: app)
            }
            Spacer()
            Button("Copy lại") { onCopy(fullItem) }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private func infoBadge(icon: String, text: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
            Text(text)
                .font(.caption2)
        }
        .foregroundStyle(.secondary)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.secondary.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 4))
    }

    // MARK: - Content loading

    private func loadContent() async {
        // Load full content (image data, rich text, etc.)
        if let loader = onLoadFullContent {
            fullItem = await loader(item)
        }
        // Load image for display
        if item.type == .image {
            if let data = fullItem.imageData ?? fullItem.thumbnailData {
                image = NSImage(data: data)
            }
        }
        // Load rich text
        if item.type == .richText, let data = fullItem.richTextData {
            attributedText = RichTextUtils.attributedString(from: data)
        }
        // Generate QR code for URLs
        if item.type == .url, let url = URL(string: item.content),
           url.scheme?.hasPrefix("http") == true {
            qrImage = generateQRCode(from: url.absoluteString)
        }
        // Load file icon
        if item.type == .file, let path = fullItem.filePath {
            fileIcon = NSWorkspace.shared.icon(forFile: path)
        }
    }

    private func generateQRCode(from string: String) -> NSImage? {
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(string.utf8)
        filter.correctionLevel = "M"
        guard let output = filter.outputImage else { return nil }

        let scale: CGFloat = 4
        let scaled = output.transformed(by: CGAffineTransform(scaleX: scale, y: scale))

        let rep = NSCIImageRep(ciImage: scaled)
        let nsImage = NSImage(size: rep.size)
        nsImage.addRepresentation(rep)
        return nsImage
    }
}

// MARK: - Rich Text Display (NSViewRepresentable)

/// Wrapper để hiển thị NSAttributedString (RTF) trong SwiftUI.
private struct RichTextDisplay: NSViewRepresentable {
    let attributedString: NSAttributedString

    func makeNSView(context: Context) -> NSTextView {
        let tv = NSTextView()
        tv.isEditable = false
        tv.isSelectable = true
        tv.drawsBackground = false
        tv.textContainer?.lineFragmentPadding = 0
        return tv
    }

    func updateNSView(_ nsView: NSTextView, context: Context) {
        nsView.textStorage?.setAttributedString(attributedString)
    }
}
