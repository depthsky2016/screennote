import SwiftData

@MainActor
enum PreviewContainer {
    static let shared = PreviewStore()
}

@MainActor
final class PreviewStore {
    let container: ModelContainer

    init() {
        let schema = Schema([Note.self, Tag.self, NoteFolder.self])
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try! ModelContainer(for: schema, configurations: configuration)
        let context = container.mainContext
        let note = Note.mockCompleted
        context.insert(note)
    }
}
