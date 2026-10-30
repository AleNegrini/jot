import AppKit

/// Builds the menu-bar status icon: a monochrome elephant silhouette derived
/// from the system 🐘 glyph, marked as a template so macOS tints it for light
/// and dark menu bars automatically.
enum MenuBarIcon {

    /// Returns an 18x18 template image of the elephant silhouette.
    static func image() -> NSImage {
        let side: CGFloat = 18
        let size = NSSize(width: side, height: side)

        // 1) Render the color emoji into a bitmap.
        let glyph = "🐘" as NSString
        let font = NSFont.systemFont(ofSize: side * 0.95)
        let attrs: [NSAttributedString.Key: Any] = [.font: font]
        let textSize = glyph.size(withAttributes: attrs)

        let rendered = NSImage(size: size)
        rendered.lockFocus()
        glyph.draw(
            at: NSPoint(x: (side - textSize.width) / 2,
                        y: (side - textSize.height) / 2),
            withAttributes: attrs
        )
        rendered.unlockFocus()

        guard let cg = rendered.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            // Fallback: SF Symbol if emoji rendering fails for any reason.
            let fallback = NSImage(systemSymbolName: "tortoise.fill", accessibilityDescription: "Jot")
            fallback?.isTemplate = true
            return fallback ?? NSImage()
        }

        // 2) Flatten to a solid silhouette using only the glyph's alpha, so the
        //    template tinting produces a clean elephant shape (not a muddy
        //    grayscale blob).
        let w = cg.width, h = cg.height
        let cs = CGColorSpaceCreateDeviceRGB()
        let ctx = CGContext(
            data: nil, width: w, height: h, bitsPerComponent: 8,
            bytesPerRow: 0, space: cs,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )!
        // Clip to the glyph's alpha, then fill solid black.
        ctx.clip(to: CGRect(x: 0, y: 0, width: w, height: h), mask: cg)
        ctx.setFillColor(CGColor(red: 0, green: 0, blue: 0, alpha: 1))
        ctx.fill(CGRect(x: 0, y: 0, width: w, height: h))

        let silhouetteCG = ctx.makeImage()!
        let image = NSImage(cgImage: silhouetteCG, size: size)
        image.isTemplate = true
        return image
    }
}
