#!/usr/bin/env swift
// Generates Jot's app icon as a macOS .iconset of PNGs, then leaves it to
// `iconutil` to produce AppIcon.icns. The icon is an indigo squircle with a
// front-facing elephant FACE (head, fanned ears, curling trunk, eyes), drawn
// with Core Graphics so there are no external image dependencies.
//
// The face geometry here mirrors Sources/Jot/ElephantFace.swift. Keep the two
// in sync if you tweak the design.
//
// Usage: swift make-icon.swift   (writes ./AppIcon.iconset/*.png)

import AppKit
import CoreGraphics

// MARK: - Elephant face (color)

func drawElephantFace(in ctx: CGContext, rect: CGRect) {
    func P(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
        CGPoint(x: rect.minX + x * rect.width, y: rect.minY + y * rect.height)
    }

    let body = CGColor(red: 0.96, green: 0.96, blue: 0.98, alpha: 1)
    let earInner = CGColor(red: 0.82, green: 0.83, blue: 0.92, alpha: 1)
    let eyeColor = CGColor(red: 0.20, green: 0.22, blue: 0.38, alpha: 1)

    func mirrorT() -> CGAffineTransform {
        CGAffineTransform(translationX: rect.midX, y: 0)
            .scaledBy(x: -1, y: 1)
            .translatedBy(x: -rect.midX, y: 0)
    }

    func earPath(mirrored: Bool) -> CGPath {
        let t = mirrored ? mirrorT() : .identity
        let e = CGMutablePath()
        e.move(to: P(0.50, 0.72), transform: t)
        e.addCurve(to: P(0.08, 0.72), control1: P(0.34, 0.88), control2: P(0.12, 0.86), transform: t)
        e.addCurve(to: P(0.12, 0.30), control1: P(0.00, 0.56), control2: P(0.01, 0.40), transform: t)
        e.addCurve(to: P(0.46, 0.40), control1: P(0.24, 0.20), control2: P(0.38, 0.26), transform: t)
        e.closeSubpath()
        return e
    }
    func innerEarPath(mirrored: Bool) -> CGPath {
        let t = mirrored ? mirrorT() : .identity
        let ie = CGMutablePath()
        ie.move(to: P(0.47, 0.68), transform: t)
        ie.addCurve(to: P(0.17, 0.66), control1: P(0.34, 0.80), control2: P(0.22, 0.76), transform: t)
        ie.addCurve(to: P(0.20, 0.38), control1: P(0.10, 0.54), control2: P(0.12, 0.44), transform: t)
        ie.addCurve(to: P(0.44, 0.46), control1: P(0.30, 0.32), control2: P(0.37, 0.38), transform: t)
        ie.closeSubpath()
        return ie
    }
    func trunkPath() -> CGPath {
        let trunk = CGMutablePath()
        trunk.move(to: P(0.40, 0.50))
        trunk.addCurve(to: P(0.37, 0.12), control1: P(0.36, 0.38), control2: P(0.31, 0.22))
        trunk.addCurve(to: P(0.58, 0.14), control1: P(0.42, 0.02), control2: P(0.55, 0.03))
        trunk.addCurve(to: P(0.49, 0.25), control1: P(0.61, 0.22), control2: P(0.55, 0.23))
        trunk.addCurve(to: P(0.60, 0.50), control1: P(0.44, 0.28), control2: P(0.57, 0.38))
        trunk.closeSubpath()
        return trunk
    }
    func headPath() -> CGPath {
        CGPath(ellipseIn: CGRect(
            x: rect.minX + 0.22 * rect.width, y: rect.minY + 0.36 * rect.height,
            width: 0.56 * rect.width, height: 0.54 * rect.height), transform: nil)
    }

    func fill(_ path: CGPath, _ color: CGColor) {
        ctx.addPath(path); ctx.setFillColor(color); ctx.fillPath()
    }

    // soft shadow under the whole face
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -rect.height * 0.012),
                  blur: rect.height * 0.03,
                  color: CGColor(red: 0, green: 0, blue: 0, alpha: 0.22))
    fill(earPath(mirrored: false), body)
    fill(earPath(mirrored: true), body)
    fill(trunkPath(), body)
    fill(headPath(), body)
    ctx.restoreGState()

    fill(innerEarPath(mirrored: false), earInner)
    fill(innerEarPath(mirrored: true), earInner)
    // head again (no shadow) to crisp the overlap over inner ears
    fill(headPath(), body)

    let r = rect.width * 0.052
    for c in [P(0.40, 0.56), P(0.60, 0.56)] {
        ctx.addEllipse(in: CGRect(x: c.x - r, y: c.y - r, width: r * 2, height: r * 2))
    }
    ctx.setFillColor(eyeColor)
    ctx.fillPath()
}

// MARK: - Icon composition

func renderIcon(size: Int) -> Data {
    let dim = CGFloat(size)
    let cs = CGColorSpaceCreateDeviceRGB()
    let ctx = CGContext(data: nil, width: size, height: size, bitsPerComponent: 8,
                        bytesPerRow: 0, space: cs,
                        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!

    let inset = dim * 0.06
    let rect = CGRect(x: inset, y: inset, width: dim - inset * 2, height: dim - inset * 2)
    let corner = rect.width * 0.2237

    ctx.saveGState()
    ctx.addPath(CGPath(roundedRect: rect, cornerWidth: corner, cornerHeight: corner, transform: nil))
    ctx.clip()
    let g = CGGradient(colorsSpace: cs, colors: [
        CGColor(red: 0.46, green: 0.49, blue: 0.99, alpha: 1),
        CGColor(red: 0.31, green: 0.35, blue: 0.88, alpha: 1)] as CFArray, locations: [0, 1])!
    ctx.drawLinearGradient(g, start: CGPoint(x: 0, y: rect.maxY), end: CGPoint(x: 0, y: rect.minY), options: [])
    ctx.restoreGState()

    drawElephantFace(in: ctx, rect: rect)

    let cgImage = ctx.makeImage()!
    return NSBitmapImageRep(cgImage: cgImage).representation(using: .png, properties: [:])!
}

// MARK: - Iconset output

let fm = FileManager.default
let outDir = URL(fileURLWithPath: "AppIcon.iconset")
try? fm.removeItem(at: outDir)
try! fm.createDirectory(at: outDir, withIntermediateDirectories: true)

let variants: [(Int, Int)] = [
    (16, 1), (16, 2), (32, 1), (32, 2), (128, 1), (128, 2),
    (256, 1), (256, 2), (512, 1), (512, 2),
]
for (point, scale) in variants {
    let pixels = point * scale
    let data = renderIcon(size: pixels)
    let name = scale == 1 ? "icon_\(point)x\(point).png" : "icon_\(point)x\(point)@2x.png"
    try! data.write(to: outDir.appendingPathComponent(name))
    print("wrote \(name) (\(pixels)px)")
}
print("Done. Now run: iconutil -c icns AppIcon.iconset")
