import SwiftUI
import KeyboardShortcuts

/// The content shown in the menu-bar popover: the full list of items plus a
/// footer with hints and an entry to Settings. Checkbox click = permanent delete.
struct ListView: View {
    @ObservedObject var store: TodoStore
    @Binding var showingSettings: Bool

    var body: some View {
        VStack(spacing: 0) {
            header

            Divider()

            if store.items.isEmpty {
                emptyState
            } else {
                list
            }

            Divider()

            footer
        }
        .frame(width: 320)
        .frame(minHeight: 200)
    }

    private var header: some View {
        HStack {
            Text("Jot")
                .font(.headline)
            Spacer()
            Text("\(store.count)")
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "checklist")
                .font(.system(size: 32))
                .foregroundStyle(.tertiary)
            Text("No items yet")
                .font(.body)
                .foregroundStyle(.secondary)
            if let s = KeyboardShortcuts.getShortcut(for: .quickAdd) {
                Text("Press \(s.description) to add one")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            } else {
                Text("Set a quick-add shortcut in Settings")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(24)
    }

    private var list: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(store.items) { item in
                    TodoRow(item: item) {
                        store.remove(item.id)
                    }
                    Divider()
                }
            }
        }
        .frame(maxHeight: 360)
    }

    private var footer: some View {
        HStack {
            Button {
                showingSettings = true
            } label: {
                Label("Settings", systemImage: "gearshape")
            }
            .buttonStyle(.plain)

            Spacer()

            Button {
                NSApp.terminate(nil)
            } label: {
                Label("Quit", systemImage: "power")
            }
            .buttonStyle(.plain)
        }
        .font(.caption)
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
    }
}

/// One row: a checkbox (click = delete) and the item text (read-only).
private struct TodoRow: View {
    let item: TodoItem
    let onDelete: () -> Void

    @State private var hovering = false

    var body: some View {
        HStack(spacing: 10) {
            Button(action: onDelete) {
                Image(systemName: "circle")
                    .font(.system(size: 16))
                    .foregroundStyle(hovering ? Color.accentColor : Color.secondary)
            }
            .buttonStyle(.plain)
            .help("Mark done (removes it)")

            Text(item.text)
                .font(.body)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .onHover { hovering = $0 }
    }
}
