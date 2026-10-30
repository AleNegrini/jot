import Foundation
import SwiftUI

/// Owns the todo list and persists it to a JSON file in Application Support.
///
/// Persistence path: ~/Library/Application Support/Jot/todos.json
@MainActor
final class TodoStore: ObservableObject {
    @Published private(set) var items: [TodoItem] = []

    private let fileURL: URL

    init() {
        let fm = FileManager.default
        let base = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = base.appendingPathComponent("Jot", isDirectory: true)
        try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
        self.fileURL = dir.appendingPathComponent("todos.json")
        load()
    }

    // MARK: - Mutations

    /// Adds a new item to the TOP of the list. Duplicates are allowed.
    /// Empty / whitespace-only text is ignored.
    func add(_ rawText: String) {
        let text = rawText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        items.insert(TodoItem(text: text), at: 0)
        save()
    }

    /// Permanently removes an item (checkbox click). No history is kept.
    func remove(_ id: UUID) {
        items.removeAll { $0.id == id }
        save()
    }

    var count: Int { items.count }

    // MARK: - Persistence

    private func load() {
        guard let data = try? Data(contentsOf: fileURL) else { return }
        if let decoded = try? JSONDecoder().decode([TodoItem].self, from: data) {
            items = decoded
        }
    }

    private func save() {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted]
        guard let data = try? encoder.encode(items) else { return }
        try? data.write(to: fileURL, options: [.atomic])
    }
}
