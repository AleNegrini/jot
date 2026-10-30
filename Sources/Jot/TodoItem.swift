import Foundation

/// A single todo entry. The user only ever sees `text`; `id` is an internal
/// identifier used to target an item when its checkbox is clicked.
/// `categoryId` optionally links the item to a user-defined `Category`.
struct TodoItem: Identifiable, Codable, Equatable {
    let id: UUID
    var text: String
    var categoryId: UUID?

    init(id: UUID = UUID(), text: String, categoryId: UUID? = nil) {
        self.id = id
        self.text = text
        self.categoryId = categoryId
    }
}
