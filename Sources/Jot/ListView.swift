import SwiftUI
import KeyboardShortcuts

/// The content shown in the menu-bar popover: the full list of items plus a
/// footer with hints and an entry to Settings. Checkbox click = permanent
/// delete. A category filter bar lets the user narrow the list; with no filter
/// the list is flat and each row shows its category badge.
struct ListView: View {
    @ObservedObject var store: TodoStore
    @Binding var showingSettings: Bool

    /// nil = show all items (flat list with category badges).
    @State private var filter: UUID? = nil

    private var visibleItems: [TodoItem] {
        guard let filter else { return store.items }
        return store.items.filter { $0.categoryId == filter }
    }

    var body: some View {
        VStack(spacing: 0) {
            header

            Divider()

            if !store.categories.isEmpty {
                filterBar
                Divider()
            }

            if visibleItems.isEmpty {
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
            Text("\(visibleItems.count)")
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                FilterChip(
                    label: "All",
                    color: .secondary,
                    filled: false,
                    selected: filter == nil
                ) {
                    filter = nil
                }

                ForEach(store.categories) { category in
                    FilterChip(
                        label: category.name,
                        color: category.color,
                        filled: true,
                        selected: filter == category.id
                    ) {
                        filter = (filter == category.id) ? nil : category.id
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "checklist")
                .font(.system(size: 32))
                .foregroundStyle(.tertiary)
            Text(filter == nil ? "No items yet" : "No items in this category")
                .font(.body)
                .foregroundStyle(.secondary)
            if filter == nil {
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
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(24)
    }

    private var list: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(visibleItems) { item in
                    TodoRow(
                        item: item,
                        category: store.category(for: item.categoryId),
                        showBadge: filter == nil
                    ) {
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

/// A category filter pill shown above the list.
private struct FilterChip: View {
    let label: String
    let color: Color
    let filled: Bool
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                if filled {
                    Circle().fill(color).frame(width: 7, height: 7)
                }
                Text(label)
                    .font(.caption.weight(selected ? .semibold : .regular))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(
                Capsule().fill(
                    selected
                        ? (filled ? color.opacity(0.22) : Color.secondary.opacity(0.18))
                        : Color.primary.opacity(0.05)
                )
            )
            .overlay(
                Capsule().stroke(selected ? (filled ? color : .secondary) : .clear, lineWidth: 1)
            )
            .foregroundStyle(selected && filled ? color : .primary)
        }
        .buttonStyle(.plain)
    }
}

/// One row: a checkbox (click = delete), the item text, and an optional
/// category badge (shown when the list is unfiltered).
private struct TodoRow: View {
    let item: TodoItem
    let category: Category?
    let showBadge: Bool
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

            if showBadge, let category {
                CategoryBadge(category: category)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .onHover { hovering = $0 }
    }
}

/// A small colored pill identifying an item's category in the flat list.
private struct CategoryBadge: View {
    let category: Category

    var body: some View {
        HStack(spacing: 4) {
            Circle().fill(category.color).frame(width: 6, height: 6)
            Text(category.name)
                .font(.caption2)
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 3)
        .background(Capsule().fill(category.color.opacity(0.18)))
        .foregroundStyle(category.color)
        .fixedSize()
    }
}
