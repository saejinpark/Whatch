// Renders the App Store header and search result artwork from the app icon and real screenshots.
//   swift Design/StoreArt.swift <repo root> <output dir>
import AppKit

let root = URL(fileURLWithPath: CommandLine.arguments[1])
let outDir = URL(fileURLWithPath: CommandLine.arguments[2])

func rgb(_ hex: UInt32, _ a: CGFloat = 1) -> CGColor {
    CGColor(red: CGFloat((hex >> 16) & 0xFF) / 255, green: CGFloat((hex >> 8) & 0xFF) / 255, blue: CGFloat(hex & 0xFF) / 255, alpha: a)
}
func image(_ path: String) -> CGImage {
    NSImage(contentsOf: root.appendingPathComponent(path))!.cgImage(forProposedRect: nil, context: nil, hints: nil)!
}
let icon = image("Whatch/Assets.xcassets/AppIcon.appiconset/Whatch_icon.png")
let shots = "AppStore/screenshots/"

func canvas(_ w: Int, _ h: Int) -> CGContext {
    let ctx = CGContext(data: nil, width: w, height: h, bitsPerComponent: 8, bytesPerRow: 0,
                        space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
    let space = CGColorSpaceCreateDeviceRGB()
    ctx.drawLinearGradient(CGGradient(colorsSpace: space, colors: [rgb(0x0E1748), rgb(0x1D357F)] as CFArray, locations: [0, 1])!,
                           start: .zero, end: CGPoint(x: w, y: h), options: [])
    let glow = CGPoint(x: Double(w) * 0.72, y: Double(h) * 0.45)
    ctx.drawRadialGradient(CGGradient(colorsSpace: space, colors: [rgb(0x2ED3C0, 0.28), rgb(0x2ED3C0, 0)] as CFArray, locations: [0, 1])!,
                           startCenter: glow, startRadius: 0, endCenter: glow, endRadius: Double(max(w, h)) * 0.45, options: [])
    return ctx
}

/// Draws an image clipped to a rounded rectangle, with a soft shadow and a hairline edge.
func place(_ ctx: CGContext, _ img: CGImage, _ rect: CGRect, radius: CGFloat) {
    let path = CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil)
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -rect.height * 0.02), blur: rect.height * 0.06, color: rgb(0x000000, 0.55))
    ctx.addPath(path); ctx.setFillColor(rgb(0x000000)); ctx.fillPath()
    ctx.restoreGState()
    ctx.saveGState()
    ctx.addPath(path); ctx.clip(); ctx.draw(img, in: rect)
    ctx.restoreGState()
    ctx.addPath(path); ctx.setStrokeColor(rgb(0xFFFFFF, 0.18)); ctx.setLineWidth(max(rect.width * 0.006, 2)); ctx.strokePath()
}

func placeIcon(_ ctx: CGContext, _ rect: CGRect) {
    place(ctx, icon, rect, radius: rect.width * 0.225)
}

func text(_ ctx: CGContext, _ string: String, size: CGFloat, weight: NSFont.Weight, color: NSColor, at point: CGPoint, centered: Bool = false) {
    let base = NSFont.systemFont(ofSize: size, weight: weight)
    let font = NSFont(descriptor: base.fontDescriptor.withDesign(.rounded)!, size: size) ?? base
    let attributed = NSAttributedString(string: string, attributes: [.font: font, .foregroundColor: color])
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(cgContext: ctx, flipped: false)
    let width = attributed.size().width
    attributed.draw(at: CGPoint(x: centered ? point.x - width / 2 : point.x, y: point.y))
    NSGraphicsContext.restoreGraphicsState()
}

func save(_ ctx: CGContext, _ name: String) {
    let rep = NSBitmapImageRep(cgImage: ctx.makeImage()!)
    try! rep.representation(using: .png, properties: [:])!.write(to: outDir.appendingPathComponent(name))
}

let mint = NSColor(red: 0.62, green: 0.95, blue: 0.90, alpha: 1)
let soft = NSColor(white: 1, alpha: 0.72)
let phoneAspect = 1320.0 / 2868.0, watchAspect = 416.0 / 496.0

// Header 3840 x 1646: brand on the left, the app on the right.
do {
    let ctx = canvas(3840, 1646)
    placeIcon(ctx, CGRect(x: 300, y: 930, width: 330, height: 330))
    text(ctx, "Whatch", size: 250, weight: .heavy, color: .white, at: CGPoint(x: 290, y: 600))
    text(ctx, "워치와 아이폰을 잇는 작은 실험실", size: 104, weight: .semibold, color: mint, at: CGPoint(x: 300, y: 450))
    text(ctx, "손전등 · 진동 · 나침반 · 배터리 · 센서", size: 70, weight: .medium, color: soft, at: CGPoint(x: 302, y: 330))

    let phoneH = 1340.0, phoneW = phoneH * phoneAspect
    let watchH = 560.0, watchW = watchH * watchAspect
    place(ctx, image(shots + "watch-46mm/watch-2-impact.png"), CGRect(x: 2160, y: 560, width: watchW, height: watchH), radius: watchW * 0.2)
    place(ctx, image(shots + "iphone-6.9/phone-2-flashlight.png"), CGRect(x: 2710, y: 153, width: phoneW, height: phoneH), radius: phoneW * 0.12)
    place(ctx, image(shots + "watch-46mm/watch-6-flashlight.png"), CGRect(x: 3240, y: 300, width: watchW, height: watchH), radius: watchW * 0.2)
    save(ctx, "header-3840x1646.png")
}

// Search result 1920 x 1280: the brand on top, the app in the middle, nothing near the edges.
do {
    let ctx = canvas(1920, 1280)
    placeIcon(ctx, CGRect(x: 610, y: 1050, width: 150, height: 150))
    text(ctx, "Whatch", size: 128, weight: .heavy, color: .white, at: CGPoint(x: 790, y: 1060))
    text(ctx, "워치와 아이폰을 잇는 작은 실험실", size: 54, weight: .semibold, color: mint, at: CGPoint(x: 960, y: 960), centered: true)

    let phoneH = 840.0, phoneW = phoneH * phoneAspect
    let watchH = 330.0, watchW = watchH * watchAspect
    place(ctx, image(shots + "iphone-6.9/phone-1-home.png"), CGRect(x: 220, y: 80, width: phoneW, height: phoneH), radius: phoneW * 0.12)
    place(ctx, image(shots + "watch-46mm/watch-6-flashlight.png"), CGRect(x: 960 - watchW - 14, y: 500, width: watchW, height: watchH), radius: watchW * 0.2)
    place(ctx, image(shots + "watch-46mm/watch-4-board.png"), CGRect(x: 960 + 14, y: 500, width: watchW, height: watchH), radius: watchW * 0.2)
    place(ctx, image(shots + "watch-46mm/watch-2-impact.png"), CGRect(x: 960 - watchW - 14, y: 140, width: watchW, height: watchH), radius: watchW * 0.2)
    place(ctx, image(shots + "watch-46mm/watch-7-heading.png"), CGRect(x: 960 + 14, y: 140, width: watchW, height: watchH), radius: watchW * 0.2)
    place(ctx, image(shots + "iphone-6.9/phone-3-heading.png"), CGRect(x: 1700 - phoneW, y: 80, width: phoneW, height: phoneH), radius: phoneW * 0.12)
    save(ctx, "search-1920x1280.png")
}
