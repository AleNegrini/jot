import SwiftUI
import KeyboardShortcuts
import ServiceManagement

/// Settings window: configure the two global hotkeys, launch-at-login, and
/// manage the user's categories.
struct SettingsView: View {
    @ObservedObject var store: TodoStore
    @State private var launchAtLogin = LaunchAtLogin.isEnabled

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Settings")
                    .font(.title2.bold())

                GroupBox("Global Shortcuts") {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Quick add")
                                .frame(width: 110, alignment: .leading)
                            KeyboardShortcuts.Recorder(for: .quickAdd)
                        }
                        HStack {
                            Text("Show list")
                                .frame(width: 110, alignment: .leading)
                            KeyboardShortcuts.Recorder(for: .showList)
                        }
                    }
                    .padding(8)
                }

                GroupBox("Categories") {
                    CategoryManager(store: store)
                        .padding(8)
                }

                GroupBox("General") {
                    Toggle("Launch at login", isOn: $launchAtLogin)
                        .onChange(of: launchAtLogin) { _, newValue in
                            LaunchAtLogin.isEnabled = newValue
                        }
                        .padding(8)
                }
            }
            .padding(20)
        }
        .frame(width: 420, height: 520)
    }
}

/// Create, recolor, and delete categories.
private struct CategoryManager: View {
    @ObservedObject var store: TodoStore

    @State private var newName: String = ""
    @State private var newColor: String = CategoryPalette.colors[0]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Existing categories.
            if store.categories.isEmpty {
                Text("No categories yet. Add one below.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                VStack(spacing: 6) {
                    ForEach(store.categories) { category in
                        CategoryRow(store: store, category: category)
                    }
                }
            }

            Divider()

            // New-category form.
            HStack(spacing: 8) {
                ColorDots(selected: $newColor)
                TextField("New category", text: $newName)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit(create)
                Button("Add", action: create)
                    .disabled(newName.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
    }

    private func create() {
        store.addCategory(name: newName, colorHex: newColor)
        newName = ""
        newColor = CategoryPalette.suggest(existing: store.categories)
    }
}

/// A single editable category row: swatch + name + item count + delete.
private struct CategoryRow: View {
    @ObservedObject var store: TodoStore
    let category: Category

    @State private var editingName: String = ""
    @State private var editingColor: String = ""
    @State private var showColors = false

    var body: some View {
        HStack(spacing: 8) {
            Button {
                showColors.toggle()
            } label: {
                Circle()
                    .fill(Color(hex: editingColor.isEmpty ? category.colorHex : editingColor))
                    .frame(width: 16, height: 16)
                    .overlay(Circle().stroke(.white.opacity(0.2), lineWidth: 1))
            }
            .buttonStyle(.plain)
            .popover(isPresented: $showColors, arrowEdge: .bottom) {
                ColorGrid(selected: Binding(
                    get: { editingColor.isEmpty ? category.colorHex : editingColor },
                    set: { editingColor = $0; commit() }
                ))
                .padding(10)
            }

            TextField("Name", text: $editingName)
                .textFieldStyle(.plain)
                .onSubmit(commit)

            Spacer()

            Text("\(store.itemCount(for: category.id))")
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)

            Button {
                store.removeCategory(category.id)
            } label: {
                Image(systemName: "trash")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .help("Delete category")
        }
        .padding(.vertical, 2)
        .onAppear {
            editingName = category.name
            editingColor = category.colorHex
        }
    }

    private func commit() {
        store.updateCategory(
            category.id,
            name: editingName,
            colorHex: editingColor.isEmpty ? category.colorHex : editingColor
        )
    }
}

/// A tappable color swatch that opens the palette grid in a popover.
private struct ColorDots: View {
    @Binding var selected: String
    @State private var open = false

    var body: some View {
        Button {
            open.toggle()
        } label: {
            Circle()
                .fill(Color(hex: selected))
                .frame(width: 18, height: 18)
                .overlay(Circle().stroke(.white.opacity(0.25), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .popover(isPresented: $open, arrowEdge: .bottom) {
            ColorGrid(selected: Binding(
                get: { selected },
                set: { selected = $0; open = false }
            ))
            .padding(10)
        }
    }
}

/// A grid of the full palette for choosing / changing a category color.
struct ColorGrid: View {
    @Binding var selected: String

    private let columns = Array(repeating: GridItem(.fixed(26), spacing: 8), count: 5)

    var body: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(CategoryPalette.colors, id: \.self) { hex in
                Button {
                    selected = hex
                } label: {
                    Circle()
                        .fill(Color(hex: hex))
                        .frame(width: 22, height: 22)
                        .overlay(
                            Circle()
                                .stroke(Color.primary, lineWidth: selected == hex ? 2 : 0)
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }
}

/// Thin wrapper around SMAppService for the login-item toggle.
enum LaunchAtLogin {
    static var isEnabled: Bool {
        get { SMAppService.mainApp.status == .enabled }
        set {
            do {
                if newValue {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                NSLog("Jot: launch-at-login toggle failed: \(error)")
            }
        }
    }
}
