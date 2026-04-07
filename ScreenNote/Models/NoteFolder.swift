import Foundation
import SwiftData

@Model
final class NoteFolder {
    var id: UUID
    var name: String
    var icon: String
    var sortOrder: Int
    var notes: [Note]
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        icon: String = "folder",
        sortOrder: Int = 0,
        notes: [Note] = [],
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.sortOrder = sortOrder
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
