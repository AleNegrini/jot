import Foundation

/// A single todo entry. The user only ever sees `text`; `id` is an internal
/// identifier used to target an item when its checkbox is clicked.
struct TodoItem: Identifiable, Codable, Equatable {
    let id: UUID
    var text: String

    init(id: UUID = UUID(), text: String) {
        self.id = id
        self.text = text
    }
}
