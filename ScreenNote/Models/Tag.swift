import Foundation
import SwiftData

@Model
final class Tag {
    var id: UUID
    var name: String
    var color: String
    var icon: String
    var isSystem: Bool
    var notes: [Note]

    init(
        id: UUID = UUID(),
        name: String,
        color: String,
        icon: String,
        isSystem: Bool = false,
        notes: [Note] = []
    ) {
        self.id = id
        self.name = name
        self.color = color
        self.icon = icon
        self.isSystem = isSystem
        self.notes = notes
    }
}
