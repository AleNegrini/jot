import CoreGraphics

/// Shared geometry for Jot's front-facing elephant face. Coordinates are in a
/// unit square (0...1, y-UP) mapped into the target rect, so the same design
/// drives both the colorful app icon and the monochrome menu-bar silhouette.
enum ElephantFace {

    private static func mapper(_ rect: CGRect) -> (CGFloat, CGFloat) -> CGPoint {
        { x, y in CGPoint(x: rect.minX + x * rect.width, y: rect.minY + y * rect.height) }
    }

    // MARK: - Component paths

    /// One ear fan. Pass `mirrored` for the right ear.
    static func earPath(in rect: CGRect, mirrored: Bool) -> CGPath {
        let P = mapper(rect)
        let e = CGMutablePath()
        var t = CGAffineTransform.identity
        if mirrored {
            t = CGAffineTransform(translationX: rect.midX, y: 0)
                .scaledBy(x: -1, y: 1)
                .translatedBy(x: -rect.midX, y: 0)
        }
        e.move(to: P(0.50, 0.72), transform: t)
        e.addCurve(to: P(0.08, 0.72), control1: P(0.34, 0.88), control2: P(0.12, 0.86), transform: t)
        e.addCurve(to: P(0.12, 0.30), control1: P(0.00, 0.56), control2: P(0.01, 0.40), transform: t)
        e.addCurve(to: P(0.46, 0.40), control1: P(0.24, 0.20), control2: P(0.38, 0.26), transform: t)
        e.closeSubpath()
        return e
    }

    /// Inner-ear accent (lighter fill in the color icon).
    static func innerEarPath(in rect: CGRect, mirrored: Bool) -> CGPath {
        let P = mapper(rect)
        let ie = CGMutablePath()
        var t = CGAffineTransform.identity
        if mirrored {
            t = CGAffineTransform(translationX: rect.midX, y: 0)
                .scaledBy(x: -1, y: 1)
                .translatedBy(x: -rect.midX, y: 0)
        }
        ie.move(to: P(0.47, 0.68), transform: t)
        ie.addCurve(to: P(0.17, 0.66), control1: P(0.34, 0.80), control2: P(0.22, 0.76), transform: t)
        ie.addCurve(to: P(0.20, 0.38), control1: P(0.10, 0.54), control2: P(0.12, 0.44), transform: t)
        ie.addCurve(to: P(0.44, 0.46), control1: P(0.30, 0.32), control2: P(0.37, 0.38), transform: t)
        ie.closeSubpath()
        return ie
    }

    /// The trunk, curling up at the tip.
    static func trunkPath(in rect: CGRect) -> CGPath {
        let P = mapper(rect)
        let trunk = CGMutablePath()
        trunk.move(to: P(0.40, 0.50))
        trunk.addCurve(to: P(0.37, 0.12), control1: P(0.36, 0.38), control2: P(0.31, 0.22))
        trunk.addCurve(to: P(0.58, 0.14), control1: P(0.42, 0.02), control2: P(0.55, 0.03))
        trunk.addCurve(to: P(0.49, 0.25), control1: P(0.61, 0.22), control2: P(0.55, 0.23))
        trunk.addCurve(to: P(0.60, 0.50), control1: P(0.44, 0.28), control2: P(0.57, 0.38))
        trunk.closeSubpath()
        return trunk
    }

    /// The head dome.
    static func headPath(in rect: CGRect) -> CGPath {
        CGPath(ellipseIn: CGRect(
            x: rect.minX + 0.22 * rect.width,
            y: rect.minY + 0.36 * rect.height,
            width: 0.56 * rect.width,
            height: 0.54 * rect.height
        ), transform: nil)
    }

    static func eyeRects(in rect: CGRect) -> [CGRect] {
        let P = mapper(rect)
        let r = rect.width * 0.052
        return [P(0.40, 0.56), P(0.60, 0.56)].map {
            CGRect(x: $0.x - r, y: $0.y - r, width: r * 2, height: r * 2)
        }
    }

    // MARK: - Composite renders

    private static let body = CGColor(red: 0.96, green: 0.96, blue: 0.98, alpha: 1)
    private static let earInner = CGColor(red: 0.82, green: 0.83, blue: 0.92, alpha: 1)
    private static let eyeColor = CGColor(red: 0.20, green: 0.22, blue: 0.38, alpha: 1)

    /// Full-color face for the app icon.
    static func drawColor(in ctx: CGContext, rect: CGRect) {
        for m in [false, true] { fill(ctx, earPath(in: rect, mirrored: m), body) }
        for m in [false, true] { fill(ctx, innerEarPath(in: rect, mirrored: m), earInner) }
        fill(ctx, trunkPath(in: rect), body)
        fill(ctx, headPath(in: rect), body)
        for e in eyeRects(in: rect) { ctx.addEllipse(in: e) }
        ctx.setFillColor(eyeColor)
        ctx.fillPath()
    }

    /// Monochrome silhouette for the menu-bar template image. The inner ears
    /// and eyes are punched OUT (even-odd) so the shape keeps readable contours
    /// instead of collapsing into a solid blob at small sizes.
    static func drawSilhouette(in ctx: CGContext, rect: CGRect, color: CGColor) {
        ctx.saveGState()

        // 1) Fill the solid union of ears + trunk + head (non-zero winding
        //    naturally merges the overlapping shapes).
        ctx.setFillColor(color)
        for m in [false, true] { ctx.addPath(earPath(in: rect, mirrored: m)) }
        ctx.addPath(trunkPath(in: rect))
        ctx.addPath(headPath(in: rect))
        ctx.fillPath()

        // 2) Punch out the eyes (and a thin inner-ear crease) by clearing those
        //    regions, so the silhouette reads as a face, not a blob.
        ctx.setBlendMode(.clear)
        for e in eyeRects(in: rect) { ctx.addEllipse(in: e) }
        ctx.fillPath()
        ctx.restoreGState()
    }

    private static func fill(_ ctx: CGContext, _ path: CGPath, _ color: CGColor) {
        ctx.addPath(path)
        ctx.setFillColor(color)
        ctx.fillPath()
    }
}
