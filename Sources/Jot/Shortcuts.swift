import KeyboardShortcuts

/// Strongly-typed names for the two global hotkeys.
///
/// Defaults (user-configurable in Settings):
///   • quickAdd  → ⌃⌥Space  (Control+Option+Space)
///   • showList  → ⌃⌥L       (Control+Option+L)
extension KeyboardShortcuts.Name {
    static let quickAdd = KeyboardShortcuts.Name(
        "quickAdd",
        initial: KeyboardShortcuts.Shortcut(.space, modifiers: [.control, .option])
    )
    static let showList = KeyboardShortcuts.Name(
        "showList",
        initial: KeyboardShortcuts.Shortcut(.l, modifiers: [.control, .option])
    )
}
