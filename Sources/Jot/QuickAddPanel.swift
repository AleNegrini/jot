import AppKit
import SwiftUI

/// A borderless, floating Spotlight-style panel for the quick-add flow.
///
/// Triggered by the global quick-add hotkey. Shows a single text field
/// centered on screen. Return saves the item and KEEPS the panel open with a
/// cleared field (multi-add), Esc closes it.
@MainActor
final class QuickAddPanel {
    private var panel: NSPanel?
    private let store: TodoStore

    private let width: CGFloat = 580
    private let height: CGFloat = 96

    init(store: TodoStore) {
        self.store = store
    }

    /// Toggles the panel. If visible, closes it; otherwise shows it focused.
    func toggle() {
        if panel != nil {
            close()
        } else {
            show()
        }
    }

    func show() {
        if panel != nil { return }

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: width, height: height),
            styleMask: [.titled, .fullSizeContentView, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.isMovableByWindowBackground = true
        panel.standardWindowButton(.closeButton)?.isHidden = true
        panel.standardWindowButton(.miniaturizeButton)?.isHidden = true
        panel.standardWindowButton(.zoomButton)?.isHidden = true
        panel.level = .floating
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.isReleasedWhenClosed = false

        let root = QuickAddView(
            onSubmit: { [weak self] text in
                self?.store.add(text)
            },
            onCancel: { [weak self] in
                self?.close()
            }
        )
        let hosting = NSHostingView(rootView: root)
        hosting.frame = panel.contentView?.bounds ?? .zero
        hosting.autoresizingMask = [.width, .height]
        panel.contentView = hosting

        // Nudge a bit above exact center, Spotlight-like.
        if let screen = NSScreen.main {
            let frame = panel.frame
            let x = screen.frame.midX - frame.width / 2
            let y = screen.frame.midY + screen.frame.height * 0.12 - frame.height / 2
            panel.setFrameOrigin(NSPoint(x: x, y: y))
        } else {
            panel.center()
        }

        self.panel = panel
        NSApp.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)
    }

    func close() {
        panel?.orderOut(nil)
        panel = nil
    }
}

/// The SwiftUI content of the quick-add panel.
///
/// Return adds the current text and clears the field for the next item without
/// closing (multi-add). A small counter + checkmark flash confirm each add.
/// Esc closes the panel.
private struct QuickAddView: View {
    let onSubmit: (String) -> Void
    let onCancel: () -> Void

    @State private var text: String = ""
    @State private var addedCount: Int = 0
    @State private var flash: Bool = false
    @FocusState private var focused: Bool

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Image(systemName: "square.and.pencil")
                    .font(.system(size: 20, weight: .regular))
                    .foregroundStyle(.secondary)

                TextField("Jot something down…", text: $text)
                    .textFieldStyle(.plain)
                    .font(.system(size: 22, weight: .regular))
                    .focused($focused)
                    .onSubmit(submit)
                    .onExitCommand(perform: onCancel)

                if flash {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(.green)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal, 20)
            .frame(maxHeight: .infinity)

            hintBar
        }
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(.white.opacity(0.08), lineWidth: 1)
        )
        .onAppear { focused = true }
    }

    private var hintBar: some View {
        HStack(spacing: 6) {
            KeyCap("return")
            Text("Add")
            Text("·").foregroundStyle(.tertiary)
            KeyCap("esc")
            Text("Close")

            Spacer()

            if addedCount > 0 {
                Text("\(addedCount) added")
                    .foregroundStyle(.green)
                    .contentTransition(.numericText())
            }
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
    }

    private func submit() {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        onSubmit(trimmed)
        text = ""
        withAnimation(.spring(response: 0.25, dampingFraction: 0.6)) {
            addedCount += 1
            flash = true
        }
        // Clear the checkmark shortly after.
        Task {
            try? await Task.sleep(nanoseconds: 700_000_000)
            withAnimation(.easeOut(duration: 0.2)) { flash = false }
        }
    }
}

/// A small keycap-styled label for shortcut hints (e.g. ⏎ / esc).
private struct KeyCap: View {
    let label: String
    init(_ label: String) { self.label = label }

    var body: some View {
        Text(label)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .fill(.quaternary)
            )
            .foregroundStyle(.secondary)
    }
}
