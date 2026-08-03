import AppKit
import Foundation

/// Tiện ích xử lý ảnh cho clipboard: chuẩn hoá về PNG và tạo thumbnail.
enum ImageUtils {
    /// Chuyển NSImage sang dữ liệu PNG (định dạng lưu trữ chuẩn, không mất chất lượng).
    static func pngData(from image: NSImage) -> Data? {
        guard let tiff = image.tiffRepresentation,
              let rep = NSBitmapImageRep(data: tiff) else { return nil }
        return rep.representation(using: .png, properties: [:])
    }

    /// Tạo thumbnail PNG (cạnh dài tối đa `maxDimension`) để hiển thị nhanh trong danh sách.
    static func thumbnailData(from image: NSImage, maxDimension: CGFloat = 240) -> Data? {
        let size = image.size
        guard size.width > 0, size.height > 0 else { return pngData(from: image) }

        let scale = min(1, maxDimension / max(size.width, size.height))
        let target = NSSize(width: max(1, size.width * scale),
                            height: max(1, size.height * scale))

        let thumb = NSImage(size: target)
        thumb.lockFocus()
        NSGraphicsContext.current?.imageInterpolation = .high
        image.draw(in: NSRect(origin: .zero, size: target),
                   from: NSRect(origin: .zero, size: size),
                   operation: .copy,
                   fraction: 1.0)
        thumb.unlockFocus()
        return pngData(from: thumb)
    }

    /// Kích thước pixel gốc (dùng cho nhãn mô tả).
    static func pixelSize(of image: NSImage) -> (width: Int, height: Int) {
        if let rep = image.representations.first as? NSBitmapImageRep {
            return (rep.pixelsWide, rep.pixelsHigh)
        }
        return (Int(image.size.width), Int(image.size.height))
    }
}
