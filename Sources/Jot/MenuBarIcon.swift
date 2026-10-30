import AppKit

/// Builds the menu-bar status icon: a monochrome elephant-face silhouette,
/// marked as a template so macOS tints it for light and dark menu bars.
enum MenuBarIcon {

    /// Returns an 18x18 template image of the elephant face.
    static func image() -> NSImage {
        let side = 18
        let cs = CGColorSpaceCreateDeviceRGB()
        let ctx = CGContext(
            data: nil, width: side, height: side, bitsPerComponent: 8,
            bytesPerRow: 0, space: cs,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )!

        // A hair of vertical inset so the ears don't touch the top edge.
        let rect = CGRect(x: 0, y: 0, width: side, height: side).insetBy(dx: 0, dy: 1)
        ElephantFace.drawSilhouette(in: ctx, rect: rect,
                                    color: CGColor(red: 0, green: 0, blue: 0, alpha: 1))

        let cg = ctx.makeImage()!
        let image = NSImage(cgImage: cg, size: NSSize(width: side, height: side))
        image.isTemplate = true // tinted for light/dark menu bars
        return image
    }
}
