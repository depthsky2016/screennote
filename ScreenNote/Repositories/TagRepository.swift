import Foundation
import SwiftData

@MainActor
final class TagRepository {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func fetchAll() throws -> [Tag] {
        try modelContext.fetch(FetchDescriptor<Tag>()).sorted { $0.name < $1.name }
    }

    @discardableResult
    func create(name: String, color: String = "#95A5A6", icon: String = "tag") throws -> Tag {
        let tag = Tag(name: name, color: color, icon: icon)
        modelContext.insert(tag)
        try modelContext.save()
        return tag
    }

    func delete(_ tag: Tag) throws {
        modelContext.delete(tag)
        try modelContext.save()
    }

    func rename(_ tag: Tag, to newName: String) throws {
        tag.name = newName
        try modelContext.save()
    }
}
