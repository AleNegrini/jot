import AppKit

// Executable entry point. We drive the app through an explicit NSApplication +
// delegate so we have full control over the menu-bar status item, the popover,
// and global-hotkey wiring from a (non-sandboxed, locally built) .app bundle.
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory) // no Dock icon, menu-bar only
app.run()
