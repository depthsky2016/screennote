import Foundation
import SwiftData

@MainActor
final class FolderRepository {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func fetchAll() throws -> [NoteFolder] {
        try modelContext.fetch(FetchDescriptor<NoteFolder>()).sorted { $0.sortOrder < $1.sortOrder }
    }

    @discardableResult
    func create(name: String, icon: String = "folder") throws -> NoteFolder {
        let folder = NoteFolder(name: name, icon: icon)
        modelContext.insert(folder)
        try modelContext.save()
        return folder
    }

    func delete(_ folder: NoteFolder) throws {
        modelContext.delete(folder)
        try modelContext.save()
    }

    func rename(_ folder: NoteFolder, to newName: String) throws {
        folder.name = newName
        folder.updatedAt = .now
        try modelContext.save()
    }

    func moveNote(_ note: Note, to folder: NoteFolder?) throws {
        note.folder = folder
        note.updatedAt = .now
        try modelContext.save()
    }
}
