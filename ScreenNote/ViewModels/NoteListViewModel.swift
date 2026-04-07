import Foundation
import Observation
import SwiftData

@MainActor
@Observable
final class NoteListViewModel {
    private(set) var notes: [Note] = []
    private(set) var isLoading = false
    private(set) var importProgressText = ""
    var selectedSort: NoteSortOption = .pinnedFirst
    var isGridMode = false
    var activeFilter: NoteFilter = .active

    private var repository: NoteRepository?
    private var pipeline: NoteProcessingPipeline?

    func configure(appState: AppState) {
        guard repository == nil else { return }
        repository = appState.noteRepository
        pipeline = appState.processingPipeline
        try? repository?.ensureSeedTags()
        reload()
    }

    func reload() {
        guard let repository else { return }
        notes = (try? repository.fetchNotes(sortBy: selectedSort, filter: activeFilter)) ?? []
    }

    func importImages(_ items: [Data], appState: AppState) async {
        guard let repository else { return }
        isLoading = true
        defer {
            isLoading = false
            reload()
        }

        let cappedItems = Array(items.prefix(50))
        for (index, data) in cappedItems.enumerated() {
            if let note = try? await repository.createNote(from: data) {
                Task { await pipeline?.process(note) }
            }
            importProgressText = "已导入 \(index + 1) / \(cappedItems.count)"
        }
        appState.showToast("正在识别中...")
    }

    func archive(_ note: Note) {
        try? repository?.archiveNote(note)
        reload()
    }

    func retryProcessing(_ note: Note) {
        guard note.processingStatus.canRetry else { return }
        Task { await pipeline?.process(note) }
    }

    // MARK: - 批量操作

    func batchArchive(_ noteIDs: Set<UUID>) {
        guard let repository else { return }
        for id in noteIDs {
            if let note = notes.first(where: { $0.id == id }) {
                try? repository.archiveNote(note)
            }
        }
        reload()
    }

    func batchDelete(_ noteIDs: Set<UUID>) {
        guard let repository else { return }
        for id in noteIDs {
            if let note = notes.first(where: { $0.id == id }) {
                try? repository.deleteNotePermanently(note)
            }
        }
        reload()
    }

    func batchRetry(_ noteIDs: Set<UUID>) {
        for id in noteIDs {
            if let note = notes.first(where: { $0.id == id }), note.processingStatus.canRetry {
                Task { await pipeline?.process(note) }
            }
        }
    }
}
