// Regenerate the app icon with:  swift Design/AppIcon.swift Whatch_icon.png
// Then copy the PNG into both AppIcon.appiconset folders.
import AppKit
// Whatch icon: a question mark wearing a watch band around its stem. Flat, no device shapes.
let size = 1024.0
func rgb(_ hex: UInt32, _ a: CGFloat = 1) -> CGColor {
    CGColor(red: CGFloat((hex >> 16) & 0xFF) / 255, green: CGFloat((hex >> 8) & 0xFF) / 255, blue: CGFloat(hex & 0xFF) / 255, alpha: a)
}
func p(_ x: Double, _ y: Double) -> CGPoint { CGPoint(x: x * size, y: y * size) }
func rr(_ x: Double, _ y: Double, _ w: Double, _ h: Double, _ r: Double) -> CGPath {
    CGPath(roundedRect: CGRect(x: x * size, y: y * size, width: w * size, height: h * size), cornerWidth: r * size, cornerHeight: r * size, transform: nil)
}
let navy: UInt32 = 0x16215A, teal: UInt32 = 0x2ED3C0, mint: UInt32 = 0xA7F4EA, tealDeep: UInt32 = 0x1BAE9E
let ctx = CGContext(data: nil, width: Int(size), height: Int(size), bitsPerComponent: 8, bytesPerRow: 0,
                    space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
ctx.setFillColor(rgb(navy)); ctx.fill(CGRect(x: 0, y: 0, width: size, height: size))

// The question mark.
let base = NSFont.systemFont(ofSize: size * 0.74, weight: .heavy)
let font = NSFont(descriptor: base.fontDescriptor.withDesign(.rounded)!, size: size * 0.74) ?? base
let text = NSAttributedString(string: "?", attributes: [.font: font, .foregroundColor: NSColor.white])
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(cgContext: ctx, flipped: false)
let b = text.boundingRect(with: CGSize(width: size, height: size), options: [.usesLineFragmentOrigin])
let c = p(0.5, 0.51)
text.draw(at: CGPoint(x: c.x - b.width / 2 - b.origin.x, y: c.y - b.height / 2 - b.origin.y + size * 0.02))
NSGraphicsContext.restoreGraphicsState()

// The band around the stem: strap, a keeper loop, and two holes on the tail.
let bandY = 0.345, bandH = 0.125
ctx.setFillColor(rgb(teal))
ctx.addPath(rr(0.30, bandY, 0.40, bandH, 0.032)); ctx.fillPath()
// The strap passes behind the stem on one side: a slightly deeper shade suggests the wrap.
ctx.setFillColor(rgb(tealDeep))
ctx.addPath(rr(0.555, bandY, 0.145, bandH, 0.032)); ctx.fillPath()
// Keeper loop at the stem.
ctx.setFillColor(rgb(mint))
ctx.addPath(rr(0.466, bandY - 0.012, 0.068, bandH + 0.024, 0.016)); ctx.fillPath()
// Holes.
ctx.setFillColor(rgb(navy))
for x in [0.345, 0.395] {
    ctx.fillEllipse(in: CGRect(x: size * x - size * 0.015, y: size * (bandY + bandH / 2) - size * 0.015, width: size * 0.03, height: size * 0.03))
}
let rep = NSBitmapImageRep(cgImage: ctx.makeImage()!)
try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: CommandLine.arguments[1]))
