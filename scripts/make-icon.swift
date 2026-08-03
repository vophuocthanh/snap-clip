import AppKit

// Vẽ app icon SnapClip (clipboard + hint lịch sử) ra PNG 1024×1024.
// Chạy: swift scripts/make-icon.swift  → xuất /tmp/SnapClip-icon.png

let S: CGFloat = 1024
let image = NSImage(size: NSSize(width: S, height: S))
image.lockFocus()
let ctx = NSGraphicsContext.current!.cgContext

func color(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ a: CGFloat = 1) -> NSColor {
    NSColor(srgbRed: r/255, green: g/255, blue: b/255, alpha: a)
}

// ---- Nền squircle với gradient ----
let pad: CGFloat = 100
let bgRect = NSRect(x: pad, y: pad, width: S - 2*pad, height: S - 2*pad)
let corner = (S - 2*pad) * 0.2237
let squircle = NSBezierPath(roundedRect: bgRect, xRadius: corner, yRadius: corner)

ctx.saveGState()
squircle.addClip()
let grad = NSGradient(colors: [
    color(122, 141, 255),   // indigo sáng (trên-trái)
    color(75, 92, 226),     // indigo
    color(58, 70, 190)      // indigo đậm (dưới-phải)
])!
grad.draw(in: bgRect, angle: -55)

// Ánh sáng nhẹ phía trên
let glow = NSGradient(colors: [color(255, 255, 255, 0.22), color(255, 255, 255, 0)])!
glow.draw(in: NSRect(x: pad, y: S/2, width: S - 2*pad, height: S/2 - pad), angle: -90)
ctx.restoreGState()

// ---- Card phía sau (hint lịch sử/nhiều mục) ----
func roundedRect(_ r: NSRect, _ rad: CGFloat) -> NSBezierPath {
    NSBezierPath(roundedRect: r, xRadius: rad, yRadius: rad)
}

let boardW: CGFloat = 420, boardH: CGFloat = 520
let boardX = (S - boardW) / 2
let boardY = (S - boardH) / 2 - 10

ctx.saveGState()
let backCard = roundedRect(NSRect(x: boardX + 42, y: boardY + 34, width: boardW, height: boardH), 54)
color(255, 255, 255, 0.28).setFill()
backCard.fill()
ctx.restoreGState()

// ---- Bảng clipboard chính (trắng, có bóng) ----
ctx.saveGState()
ctx.setShadow(offset: CGSize(width: 0, height: -14), blur: 34,
              color: color(20, 26, 70, 0.35).cgColor)
let board = roundedRect(NSRect(x: boardX, y: boardY, width: boardW, height: boardH), 54)
color(255, 255, 255).setFill()
board.fill()
ctx.restoreGState()

// ---- Kẹp (clip) trên đỉnh bảng ----
let clipW: CGFloat = 176, clipH: CGFloat = 92
let clipX = (S - clipW) / 2
let clipY = boardY + boardH - clipH/2 - 6
let clip = roundedRect(NSRect(x: clipX, y: clipY, width: clipW, height: clipH), 30)
color(74, 92, 210).setFill()
clip.fill()
// lỗ kẹp
let hole = roundedRect(NSRect(x: S/2 - 34, y: clipY + clipH/2 - 12, width: 68, height: 26), 13)
color(255, 255, 255, 0.9).setFill()
hole.fill()

// ---- Các dòng nội dung ----
let lineX = boardX + 62
let lineW = boardW - 124
func line(y: CGFloat, w: CGFloat, _ c: NSColor) {
    let r = roundedRect(NSRect(x: lineX, y: y, width: w, height: 40), 20)
    c.setFill(); r.fill()
}
line(y: boardY + boardH - 190, w: lineW * 0.8, color(110, 130, 245))       // dòng nhấn
line(y: boardY + boardH - 270, w: lineW,        color(206, 212, 232))
line(y: boardY + boardH - 350, w: lineW,        color(206, 212, 232))
line(y: boardY + boardH - 430, w: lineW * 0.6,  color(206, 212, 232))

image.unlockFocus()

// ---- Xuất PNG ----
guard let tiff = image.tiffRepresentation,
      let rep = NSBitmapImageRep(data: tiff),
      let png = rep.representation(using: .png, properties: [:]) else {
    FileHandle.standardError.write("Lỗi tạo PNG\n".data(using: .utf8)!)
    exit(1)
}
let out = "/tmp/SnapClip-icon.png"
try? png.write(to: URL(fileURLWithPath: out))
print("✓ \(out)")
