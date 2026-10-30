#!/usr/bin/env swift
// Generates Jot's app icon as a macOS .iconset of PNGs, then leaves it to
// `iconutil` to produce AppIcon.icns. The icon is an indigo squircle with the
// system elephant glyph (🐘) centered on it — a high-quality, consistent
// rendering with no external image dependencies.
//
// Usage: swift make-icon.swift   (writes ./AppIcon.iconset/*.png)

import AppKit
import CoreGraphics
import CoreText

// MARK: - Drawing

/// Renders the icon into a `size`x`size` bitmap and returns PNG data.
func renderIcon(size: Int) -> Data {
    let dim = CGFloat(size)
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let ctx = CGContext(
        data: nil,
        width: size,
        height: size,
        bitsPerComponent: 8,
        bytesPerRow: 0,
        space: colorSpace,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    )!

    // --- Background squircle with a soft vertical gradient ---
    let inset = dim * 0.06
    let rect = CGRect(x: inset, y: inset, width: dim - inset * 2, height: dim - inset * 2)
    let corner = rect.width * 0.2237
    let bgPath = CGPath(roundedRect: rect, cornerWidth: corner, cornerHeight: corner, transform: nil)

    ctx.saveGState()
    ctx.addPath(bgPath)
    ctx.clip()
    let gradient = CGGradient(
        colorsSpace: colorSpace,
        colors: [
            CGColor(red: 0.46, green: 0.49, blue: 0.99, alpha: 1), // top
            CGColor(red: 0.31, green: 0.35, blue: 0.88, alpha: 1)  // bottom
        ] as CFArray,
        locations: [0, 1]
    )!
    ctx.drawLinearGradient(
        gradient,
        start: CGPoint(x: 0, y: rect.maxY),
        end: CGPoint(x: 0, y: rect.minY),
        options: []
    )
    ctx.restoreGState()

    // --- Elephant emoji, centered ---
    // Draw into an NSImage-backed context so the color emoji font renders.
    let glyph = "🐘" as NSString
    let fontSize = rect.height * 0.70
    let font = NSFont.systemFont(ofSize: fontSize)

    let nsImage = NSImage(size: NSSize(width: dim, height: dim))
    nsImage.lockFocus()
    let attrs: [NSAttributedString.Key: Any] = [.font: font]
    let textSize = glyph.size(withAttributes: attrs)
    let drawPoint = NSPoint(
        x: rect.midX - textSize.width / 2,
        y: rect.midY - textSize.height / 2 + rect.height * 0.02
    )
    glyph.draw(at: drawPoint, withAttributes: attrs)
    nsImage.unlockFocus()

    if let cg = nsImage.cgImage(forProposedRect: nil, context: nil, hints: nil) {
        // Soft drop shadow to lift the elephant off the background.
        ctx.saveGState()
        ctx.setShadow(offset: CGSize(width: 0, height: -dim * 0.012),
                      blur: dim * 0.03,
                      color: CGColor(red: 0, green: 0, blue: 0, alpha: 0.30))
        ctx.draw(cg, in: CGRect(x: 0, y: 0, width: dim, height: dim))
        ctx.restoreGState()
    }

    // --- Encode PNG ---
    let cgImage = ctx.makeImage()!
    let rep = NSBitmapImageRep(cgImage: cgImage)
    return rep.representation(using: .png, properties: [:])!
}

// MARK: - Iconset output

let fm = FileManager.default
let outDir = URL(fileURLWithPath: "AppIcon.iconset")
try? fm.removeItem(at: outDir)
try! fm.createDirectory(at: outDir, withIntermediateDirectories: true)

let variants: [(Int, Int)] = [
    (16, 1), (16, 2),
    (32, 1), (32, 2),
    (128, 1), (128, 2),
    (256, 1), (256, 2),
    (512, 1), (512, 2),
]

for (point, scale) in variants {
    let pixels = point * scale
    let data = renderIcon(size: pixels)
    let name = scale == 1 ? "icon_\(point)x\(point).png" : "icon_\(point)x\(point)@2x.png"
    try! data.write(to: outDir.appendingPathComponent(name))
    print("wrote \(name) (\(pixels)px)")
}

print("Done. Now run: iconutil -c icns AppIcon.iconset")
