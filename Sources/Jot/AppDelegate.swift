import AppKit
import SwiftUI
import Combine
import KeyboardShortcuts

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let store = TodoStore()
    private lazy var quickAdd = QuickAddPanel(store: store)

    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var settingsWindow: NSWindow?
    private var cancellables = Set<AnyCancellable>()
    private let showingSettings = SettingsFlag()

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusItem()
        setupPopover()
        setupHotkeys()
        observeStore()
        updateBadge()
        promptForAccessibilityIfNeeded()
    }

    // MARK: - Menu-bar status item

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            // Elephant silhouette, template-tinted for light/dark menu bars.
            button.image = MenuBarIcon.image()
            button.imagePosition = .imageLeading
            button.action = #selector(togglePopover)
            button.target = self
        }
    }

    private func setupPopover() {
        popover = NSPopover()
        popover.behavior = .transient
        popover.contentSize = NSSize(width: 320, height: 400)
        let root = ListView(store: store, showingSettings: showingSettings.binding)
        popover.contentViewController = NSHostingController(rootView: root)

        // React to the Settings flag flipping from inside the SwiftUI list.
        showingSettings.onOpen = { [weak self] in
            self?.openSettings()
        }
    }

    @objc private func togglePopover() {
        guard let button = statusItem.button else { return }
        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }

    private func showPopover() {
        guard let button = statusItem.button else { return }
        if !popover.isShown {
            NSApp.activate(ignoringOtherApps: true)
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }

    // MARK: - Global hotkeys

    private func setupHotkeys() {
        KeyboardShortcuts.onKeyUp(for: .quickAdd) { [weak self] in
            self?.quickAdd.toggle()
        }
        KeyboardShortcuts.onKeyUp(for: .showList) { [weak self] in
            self?.showPopover()
        }
    }

    // MARK: - Badge

    private func observeStore() {
        store.$items
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.updateBadge() }
            .store(in: &cancellables)
    }

    private func updateBadge() {
        guard let button = statusItem.button else { return }
        button.title = store.count > 0 ? " \(store.count)" : ""
    }

    // MARK: - Settings window

    private func openSettings() {
        popover.performClose(nil)

        if let window = settingsWindow {
            NSApp.activate(ignoringOtherApps: true)
            window.makeKeyAndOrderFront(nil)
            return
        }

        let hosting = NSHostingController(rootView: SettingsView())
        let window = NSWindow(contentViewController: hosting)
        window.title = "Jot Settings"
        window.styleMask = [.titled, .closable]
        window.isReleasedWhenClosed = false
        window.center()
        settingsWindow = window

        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }

    // MARK: - Accessibility permission

    private func promptForAccessibilityIfNeeded() {
        // Global hotkeys need an event tap; macOS gates this behind the
        // Accessibility permission. Guide the user once if it's missing.
        let trusted = AXIsProcessTrusted()
        if trusted { return }

        let alert = NSAlert()
        alert.messageText = "Enable Accessibility for Jot"
        alert.informativeText = """
        Jot uses a global keyboard shortcut to open the quick-add box from \
        anywhere. macOS requires Accessibility permission for this.

        Open System Settings → Privacy & Security → Accessibility and enable Jot.
        """
        alert.addButton(withTitle: "Open System Settings")
        alert.addButton(withTitle: "Later")
        NSApp.activate(ignoringOtherApps: true)
        if alert.runModal() == .alertFirstButtonReturn {
            let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
            NSWorkspace.shared.open(url)
        }
    }
}

/// Bridges a SwiftUI `@Binding<Bool>` (set when "Settings" is tapped in the
/// list) to an AppKit callback that opens the settings window.
@MainActor
final class SettingsFlag: ObservableObject {
    @Published var value = false {
        didSet {
            if value {
                value = false
                onOpen?()
            }
        }
    }
    var onOpen: (() -> Void)?

    var binding: Binding<Bool> {
        Binding(get: { self.value }, set: { self.value = $0 })
    }
}
