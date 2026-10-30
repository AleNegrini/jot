import AppKit
import SwiftUI

/// A borderless, floating Spotlight-style panel for the quick-add flow.
///
/// Triggered by the global quick-add hotkey. Shows a single text field plus a
/// category picker. Return saves the item and KEEPS the panel open with a
/// cleared field (multi-add), Esc closes it.
@MainActor
final class QuickAddPanel {
    private var panel: NSPanel?
    private let store: TodoStore

    private let width: CGFloat = 620
    private let height: CGFloat = 150

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
            store: store,
            onSubmit: { [weak self] text, categoryId in
                self?.store.add(text, categoryId: categoryId)
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

/// The SwiftUI content of the quick-add panel, styled after Raycast.
///
/// Return adds the current text and clears the field for the next item without
/// closing (multi-add). A small counter + checkmark flash confirm each add.
/// Esc closes the panel. A category chip row lets the user tag the item; the
/// last-used category is remembered for the session.
private struct QuickAddView: View {
    @ObservedObject var store: TodoStore
    let onSubmit: (String, UUID?) -> Void
    let onCancel: () -> Void

    @State private var text: String = ""
    @State private var selectedCategoryId: UUID? = nil
    @State private var addedCount: Int = 0
    @State private var flash: Bool = false
    @FocusState private var focused: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Input row.
            HStack(spacing: 14) {
                Image(systemName: "square.and.pencil")
                    .font(.system(size: 22, weight: .regular))
                    .foregroundStyle(selectedColor ?? .secondary)

                TextField("Jot something down…", text: $text)
                    .textFieldStyle(.plain)
                    .font(.system(size: 24, weight: .regular))
                    .focused($focused)
                    .onSubmit(submit)
                    .onExitCommand(perform: onCancel)

                if flash {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(.green)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal, 22)
            .padding(.top, 20)
            .padding(.bottom, 14)

            Divider().opacity(0.4)

            categoryBar

            Divider().opacity(0.4)

            hintBar
        }
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(.white.opacity(0.10), lineWidth: 1)
        )
        .onAppear { focused = true }
    }

    private var selectedColor: Color? {
        store.category(for: selectedCategoryId)?.color
    }

    private var categoryBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                CategoryChip(
                    label: "None",
                    color: .secondary,
                    selected: selectedCategoryId == nil,
                    filled: false
                ) {
                    selectedCategoryId = nil
                }

                ForEach(store.categories) { category in
                    CategoryChip(
                        label: category.name,
                        color: category.color,
                        selected: selectedCategoryId == category.id,
                        filled: true
                    ) {
                        selectedCategoryId = category.id
                    }
                }

                if store.categories.isEmpty {
                    Text("Create categories in Settings")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 10)
        }
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
        .padding(.horizontal, 22)
        .padding(.vertical, 9)
    }

    private func submit() {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        onSubmit(trimmed, selectedCategoryId)
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

/// A selectable, colored category chip for the quick-add picker.
private struct CategoryChip: View {
    let label: String
    let color: Color
    let selected: Bool
    let filled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if filled {
                    Circle()
                        .fill(color)
                        .frame(width: 8, height: 8)
                }
                Text(label)
                    .font(.system(size: 13, weight: selected ? .semibold : .regular))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule().fill(
                    selected
                        ? (filled ? color.opacity(0.22) : Color.secondary.opacity(0.18))
                        : Color.primary.opacity(0.05)
                )
            )
            .overlay(
                Capsule().stroke(
                    selected ? (filled ? color : Color.secondary) : .clear,
                    lineWidth: 1
                )
            )
            .foregroundStyle(selected && filled ? color : .primary)
        }
        .buttonStyle(.plain)
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
