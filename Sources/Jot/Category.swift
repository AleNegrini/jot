import SwiftUI

/// A user-defined category used to group todo items.
///
/// Each category has a stable `id`, a display `name`, and a `colorHex` used to
/// tint its badge in the UI. Categories are created/edited from Settings.
struct Category: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    var name: String
    /// A 6-digit hex string without leading `#`, e.g. "FF8800".
    var colorHex: String

    init(id: UUID = UUID(), name: String, colorHex: String) {
        self.id = id
        self.name = name
        self.colorHex = colorHex
    }

    var color: Color { Color(hex: colorHex) }
}

/// A small palette of pleasant, Raycast-ish accent colors offered when
/// creating a new category.
enum CategoryPalette {
    static let colors: [String] = [
        "FF6B6B", // red
        "F7905B", // orange
        "FFD166", // yellow
        "4ECB71", // green
        "41C7C7", // teal
        "4D9DE0", // blue
        "7B6EF6", // indigo
        "C86DD7", // purple
        "F06595", // pink
        "9AA0A6", // gray
    ]

    /// Picks the palette color least used so new categories look distinct.
    static func suggest(existing: [Category]) -> String {
        var counts: [String: Int] = [:]
        for c in colors { counts[c] = 0 }
        for cat in existing {
            counts[cat.colorHex, default: 0] += 1
        }
        return colors.min { (counts[$0] ?? 0) < (counts[$1] ?? 0) } ?? colors[0]
    }
}

extension Color {
    /// Builds a Color from a 6-digit hex string (optionally prefixed with `#`).
    init(hex: String) {
        let cleaned = hex.hasPrefix("#") ? String(hex.dropFirst()) : hex
        var value: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&value)
        let r = Double((value & 0xFF0000) >> 16) / 255.0
        let g = Double((value & 0x00FF00) >> 8) / 255.0
        let b = Double(value & 0x0000FF) / 255.0
        self.init(.sRGB, red: r, green: g, blue: b, opacity: 1.0)
    }
}
