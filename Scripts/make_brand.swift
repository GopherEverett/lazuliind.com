import AppKit
import CoreGraphics
import Foundation

// Renders Lazuli Industries brand images into brand/:
//   developer-icon-512.png     Google Play developer page icon (512 x 512)
//   developer-header-4096.png  Google Play developer page header (4096 x 2304; saved as .jpg below)
// Usage: swift Scripts/make_brand.swift   (run from the repo root)

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let out = root.appendingPathComponent("brand")
let space = CGColorSpace(name: CGColorSpace.sRGB)!

func rgb(_ hex: UInt32, _ a: CGFloat = 1) -> CGColor {
    CGColor(srgbRed: CGFloat((hex >> 16) & 0xFF) / 255, green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255, alpha: a)
}

let deepNavy = rgb(0x0A1830), lazuli = rgb(0x1F4E8C), gold = rgb(0xE3B341)

func context(_ w: Int, _ h: Int) -> CGContext {
    CGContext(data: nil, width: w, height: h, bitsPerComponent: 8, bytesPerRow: 0, space: space,
              bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
}

func background(_ ctx: CGContext, _ w: CGFloat, _ h: CGFloat) {
    let g = CGGradient(colorsSpace: space, colors: [lazuli, deepNavy] as CFArray, locations: [0, 1])!
    ctx.drawLinearGradient(g, start: CGPoint(x: 0, y: h), end: CGPoint(x: w, y: 0), options: [])
}

/// A cut gemstone in a 1024 design space (origin bottom-left), centered at (512, 512).
func drawGem(_ ctx: CGContext) {
    let tableL = CGPoint(x: 402, y: 780), tableR = CGPoint(x: 622, y: 780)
    let girdleL = CGPoint(x: 232, y: 640), girdleR = CGPoint(x: 792, y: 640)
    let culet = CGPoint(x: 512, y: 214)
    let midL = CGPoint(x: 402, y: 640), midR = CGPoint(x: 622, y: 640), mid = CGPoint(x: 512, y: 640)

    func poly(_ pts: [CGPoint], _ color: CGColor) {
        ctx.beginPath(); ctx.move(to: pts[0]); pts.dropFirst().forEach { ctx.addLine(to: $0) }; ctx.closePath()
        ctx.setFillColor(color); ctx.fillPath()
    }
    // Crown (top) facets, lit from the upper left.
    poly([girdleL, tableL, midL], rgb(0x8DB8F5))
    poly([tableL, tableR, midR, midL], rgb(0x6FA3EF))
    poly([tableR, girdleR, midR], rgb(0x3D7BD6))
    // Pavilion (bottom) facets.
    poly([girdleL, midL, culet], rgb(0x2F69C2))
    poly([midL, mid, culet], rgb(0x2A5FB0))
    poly([mid, midR, culet], rgb(0x1F4E8C))
    poly([midR, girdleR, culet], rgb(0x183F73))
    // Facet edges.
    ctx.setStrokeColor(rgb(0xFFFFFF, 0.22)); ctx.setLineWidth(5); ctx.setLineJoin(.round)
    for (a, b) in [(girdleL, girdleR), (tableL, midL), (tableR, midR), (midL, culet), (mid, culet), (midR, culet)] {
        ctx.move(to: a); ctx.addLine(to: b)
    }
    ctx.strokePath()
    ctx.beginPath()
    ctx.move(to: girdleL); [tableL, tableR, girdleR, culet].forEach { ctx.addLine(to: $0) }; ctx.closePath()
    ctx.setStrokeColor(rgb(0xFFFFFF, 0.35)); ctx.setLineWidth(6); ctx.strokePath()
    // Pyrite flecks: the gold in lapis lazuli.
    ctx.setFillColor(gold)
    for (x, y, r) in [(352.0, 600.0, 15.0), (548.0, 470.0, 12.0), (470.0, 360.0, 9.0), (640.0, 590.0, 8.0)] {
        ctx.fillEllipse(in: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2))
    }
}

func save(_ ctx: CGContext, _ name: String) {
    try? FileManager.default.createDirectory(at: out, withIntermediateDirectories: true)
    let url = out.appendingPathComponent(name)
    let dest = CGImageDestinationCreateWithURL(url as CFURL, "public.png" as CFString, 1, nil)!
    CGImageDestinationAddImage(dest, ctx.makeImage()!, nil)
    CGImageDestinationFinalize(dest)
    print("wrote brand/\(name)")
}

// Developer icon: 512 x 512, gem centered with room for Play's rounded mask.
do {
    let ctx = context(512, 512)
    background(ctx, 512, 512)
    ctx.scaleBy(x: 0.5, y: 0.5)
    ctx.translateBy(x: 512, y: 512); ctx.scaleBy(x: 0.92, y: 0.92); ctx.translateBy(x: -512, y: -497)
    drawGem(ctx)
    save(ctx, "developer-icon-512.png")
}

// Developer header: 4096 x 2304 (16:9). Play crops the edges on some screens,
// so the gem and name stay in the middle third.
do {
    let w = 4096, h = 2304
    let ctx = context(w, h)
    background(ctx, CGFloat(w), CGFloat(h))
    // A faint large gem on the right for texture.
    ctx.saveGState()
    ctx.setAlpha(0.07)
    ctx.translateBy(x: 3300, y: 1150); ctx.scaleBy(x: 2.6, y: 2.6); ctx.translateBy(x: -512, y: -470)
    drawGem(ctx)
    ctx.restoreGState()

    ctx.saveGState()
    ctx.translateBy(x: 2048, y: 1420); ctx.scaleBy(x: 0.72, y: 0.72); ctx.translateBy(x: -512, y: -470)
    drawGem(ctx)
    ctx.restoreGState()

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(cgContext: ctx, flipped: false)
    func centered(_ text: String, size: CGFloat, weight: NSFont.Weight, color: NSColor, y: CGFloat, kern: CGFloat = 0) {
        let s = NSAttributedString(string: text, attributes: [
            .font: NSFont.systemFont(ofSize: size, weight: weight), .foregroundColor: color, .kern: kern,
        ])
        s.draw(at: CGPoint(x: (CGFloat(w) - s.size().width) / 2, y: y))
    }
    centered("Lazuli Industries", size: 230, weight: .bold, color: .white, y: 760)
    centered("Property management  ·  Web and app development", size: 104, weight: .medium,
             color: NSColor(srgbRed: 0.89, green: 0.70, blue: 0.25, alpha: 1), y: 580, kern: 1)
    NSGraphicsContext.restoreGraphicsState()
    save(ctx, "developer-header-4096.png")
}
