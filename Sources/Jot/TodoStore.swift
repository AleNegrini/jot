import Foundation
import SwiftUI

/// Owns the todo list + categories and persists them to JSON files in
/// Application Support.
///
/// Persistence paths:
///   ~/Library/Application Support/Jot/todos.json
///   ~/Library/Application Support/Jot/categories.json
@MainActor
final class TodoStore: ObservableObject {
    @Published private(set) var items: [TodoItem] = []
    @Published private(set) var categories: [Category] = []

    private let todosURL: URL
    private let categoriesURL: URL

    init() {
        let fm = FileManager.default
        let base = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = base.appendingPathComponent("Jot", isDirectory: true)
        try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
        self.todosURL = dir.appendingPathComponent("todos.json")
        self.categoriesURL = dir.appendingPathComponent("categories.json")
        load()
    }

    // MARK: - Item mutations

    /// Adds a new item to the TOP of the list. Duplicates are allowed.
    /// Empty / whitespace-only text is ignored.
    func add(_ rawText: String, categoryId: UUID? = nil) {
        let text = rawText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        items.insert(TodoItem(text: text, categoryId: categoryId), at: 0)
        saveItems()
    }

    /// Permanently removes an item (checkbox click). No history is kept.
    func remove(_ id: UUID) {
        items.removeAll { $0.id == id }
        saveItems()
    }

    var count: Int { items.count }

    /// Looks up a category by id, if any.
    func category(for id: UUID?) -> Category? {
        guard let id else { return nil }
        return categories.first { $0.id == id }
    }

    /// Number of (non-deleted) items in a given category.
    func itemCount(for categoryId: UUID) -> Int {
        items.filter { $0.categoryId == categoryId }.count
    }

    // MARK: - Category mutations

    /// Creates a new category. Blank names are ignored. Returns the created id.
    @discardableResult
    func addCategory(name: String, colorHex: String) -> UUID? {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let category = Category(name: trimmed, colorHex: colorHex)
        categories.append(category)
        saveCategories()
        return category.id
    }

    /// Updates an existing category's name and color.
    func updateCategory(_ id: UUID, name: String, colorHex: String) {
        guard let idx = categories.firstIndex(where: { $0.id == id }) else { return }
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        categories[idx].name = trimmed
        categories[idx].colorHex = colorHex
        saveCategories()
    }

    /// Removes a category and clears it from any items that referenced it.
    func removeCategory(_ id: UUID) {
        categories.removeAll { $0.id == id }
        var changed = false
        for idx in items.indices where items[idx].categoryId == id {
            items[idx].categoryId = nil
            changed = true
        }
        saveCategories()
        if changed { saveItems() }
    }

    // MARK: - Persistence

    private func load() {
        if let data = try? Data(contentsOf: todosURL),
           let decoded = try? JSONDecoder().decode([TodoItem].self, from: data) {
            items = decoded
        }
        if let data = try? Data(contentsOf: categoriesURL),
           let decoded = try? JSONDecoder().decode([Category].self, from: data) {
            categories = decoded
        }
    }

    private func saveItems() {
        write(items, to: todosURL)
    }

    private func saveCategories() {
        write(categories, to: categoriesURL)
    }

    private func write<T: Encodable>(_ value: T, to url: URL) {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted]
        guard let data = try? encoder.encode(value) else { return }
        try? data.write(to: url, options: [.atomic])
    }
}
