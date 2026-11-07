// Renders the DesktopDüzen app icon (glass zones on a gradient) and writes Resources/AppIcon.icns.
// Usage: swift scripts/make_icon.swift <output-dir>
import AppKit

let outDir = URL(fileURLWithPath: CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "Resources")

func renderIcon(size: CGFloat) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()
    guard let ctx = NSGraphicsContext.current?.cgContext else { fatalError() }
    let s = size / 1024.0
    ctx.scaleBy(x: s, y: s)

    // macOS icon grid: 824pt squircle centred in 1024 with drop shadow.
    let tile = CGRect(x: 100, y: 100, width: 824, height: 824)
    let squircle = NSBezierPath(roundedRect: tile, xRadius: 185, yRadius: 185)

    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -12), blur: 28, color: NSColor.black.withAlphaComponent(0.35).cgColor)
    NSColor.black.setFill()
    squircle.fill()
    ctx.restoreGState()

    // Background gradient: deep indigo -> violet -> electric blue.
    ctx.saveGState()
    squircle.addClip()
    let bg = NSGradient(colors: [
        NSColor(srgbRed: 0.10, green: 0.16, blue: 0.55, alpha: 1),
        NSColor(srgbRed: 0.36, green: 0.20, blue: 0.80, alpha: 1),
        NSColor(srgbRed: 0.12, green: 0.62, blue: 0.98, alpha: 1)
    ], atLocations: [0, 0.5, 1], colorSpace: .sRGB)!
    bg.draw(in: tile, angle: 60)

    // Soft glow blobs for depth.
    func glow(_ c: CGPoint, _ r: CGFloat, _ color: NSColor) {
        let g = NSGradient(colors: [color, color.withAlphaComponent(0)])!
        g.draw(fromCenter: c, radius: 0, toCenter: c, radius: r, options: [])
    }
    glow(CGPoint(x: 260, y: 820), 420, NSColor(srgbRed: 1.0, green: 0.45, blue: 0.85, alpha: 0.55))
    glow(CGPoint(x: 820, y: 230), 380, NSColor(srgbRed: 0.30, green: 0.95, blue: 1.0, alpha: 0.45))

    // Glass zone panels.
    func glassPanel(_ rect: CGRect, radius: CGFloat, tint: NSColor) {
        let path = NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
        ctx.saveGState()
        ctx.setShadow(offset: CGSize(width: 0, height: -10), blur: 24, color: NSColor.black.withAlphaComponent(0.28).cgColor)
        NSColor.white.withAlphaComponent(0.22).setFill()
        path.fill()
        ctx.restoreGState()

        ctx.saveGState()
        path.addClip()
        tint.withAlphaComponent(0.18).setFill()
        path.fill()
        // Sheen on the upper part.
        let sheen = NSGradient(colors: [NSColor.white.withAlphaComponent(0.55), NSColor.white.withAlphaComponent(0.0)])!
        sheen.draw(in: CGRect(x: rect.minX, y: rect.midY, width: rect.width, height: rect.height / 2), angle: -90)
        // Title bar strip.
        NSColor.white.withAlphaComponent(0.20).setFill()
        CGRect(x: rect.minX, y: rect.maxY - 58, width: rect.width, height: 58).fill()
        ctx.restoreGState()

        // Rim highlight.
        let rim = NSBezierPath(roundedRect: rect.insetBy(dx: 2, dy: 2), xRadius: radius - 2, yRadius: radius - 2)
        rim.lineWidth = 4
        NSColor.white.withAlphaComponent(0.75).setStroke()
        rim.stroke()
    }

    func iconDots(in rect: CGRect, count: Int, colors: [NSColor]) {
        let size: CGFloat = 58
        let gap: CGFloat = 26
        let totalW = CGFloat(count) * size + CGFloat(count - 1) * gap
        var x = rect.midX - totalW / 2
        let y = rect.minY + (rect.height - 58) / 2 - size / 2
        for i in 0..<count {
            let r = CGRect(x: x, y: y, width: size, height: size)
            colors[i % colors.count].setFill()
            NSBezierPath(roundedRect: r, xRadius: 14, yRadius: 14).fill()
            x += size + gap
        }
    }

    let top1 = CGRect(x: 200, y: 520, width: 300, height: 300)
    let top2 = CGRect(x: 524, y: 520, width: 300, height: 300)
    let bottom = CGRect(x: 200, y: 204, width: 624, height: 290)
    glassPanel(top1, radius: 52, tint: .systemPink)
    glassPanel(top2, radius: 52, tint: .cyan)
    glassPanel(bottom, radius: 56, tint: .systemPurple)

    let palette = [NSColor(srgbRed: 1, green: 1, blue: 1, alpha: 0.92),
                   NSColor(srgbRed: 1, green: 0.85, blue: 0.35, alpha: 0.95),
                   NSColor(srgbRed: 0.55, green: 1, blue: 0.85, alpha: 0.95),
                   NSColor(srgbRed: 1, green: 0.55, blue: 0.75, alpha: 0.95)]
    iconDots(in: top1, count: 2, colors: [palette[0], palette[1]])
    iconDots(in: top2, count: 2, colors: [palette[2], palette[0]])
    iconDots(in: bottom, count: 5, colors: palette)

    // Squircle edge highlight.
    let edge = NSBezierPath(roundedRect: tile.insetBy(dx: 3, dy: 3), xRadius: 182, yRadius: 182)
    edge.lineWidth = 6
    NSColor.white.withAlphaComponent(0.22).setStroke()
    edge.stroke()
    ctx.restoreGState()

    image.unlockFocus()
    return image
}

func pngData(_ image: NSImage, pixels: Int) -> Data {
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: pixels, pixelsHigh: pixels, bitsPerSample: 8,
                               samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB,
                               bytesPerRow: 0, bitsPerPixel: 0)!
    rep.size = NSSize(width: pixels, height: pixels)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    image.draw(in: NSRect(x: 0, y: 0, width: pixels, height: pixels))
    NSGraphicsContext.restoreGraphicsState()
    return rep.representation(using: .png, properties: [:])!
}

let iconset = outDir.appendingPathComponent("AppIcon.iconset")
try? FileManager.default.removeItem(at: iconset)
try! FileManager.default.createDirectory(at: iconset, withIntermediateDirectories: true)
for base in [16, 32, 128, 256, 512] {
    for scale in [1, 2] {
        let px = base * scale
        let name = scale == 1 ? "icon_\(base)x\(base).png" : "icon_\(base)x\(base)@2x.png"
        try! pngData(renderIcon(size: CGFloat(px)), pixels: px).write(to: iconset.appendingPathComponent(name))
    }
}
try! pngData(renderIcon(size: 1024), pixels: 1024).write(to: outDir.appendingPathComponent("AppIcon-1024.png"))
print("wrote \(iconset.path)")
