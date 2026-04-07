import Foundation
import Observation
import SwiftData
import UIKit

@MainActor
@Observable
final class NoteDetailViewModel {
    var title: String
    var summary: String
    var userNote: String
    var showDeleteConfirmation = false

    let note: Note
    private let repository: NoteRepository
    private let pipeline: NoteProcessingPipeline?

    init(note: Note, repository: NoteRepository, pipeline: NoteProcessingPipeline? = nil) {
        self.note = note
        self.repository = repository
        self.pipeline = pipeline
        self.title = note.aiTitle
        self.summary = note.aiSummary
        self.userNote = note.userNote
    }

    func save() {
        note.aiTitle = title
        note.aiSummary = summary
        note.userNote = userNote
        try? repository.updateNote(note)
    }

    func delete() {
        try? repository.deleteNotePermanently(note)
    }

    func retryProcessing() async {
        guard note.processingStatus.canRetry else { return }
        await pipeline?.process(note)
        // 刷新本地状态
        title = note.aiTitle
        summary = note.aiSummary
    }

    func copyOCRText() {
        UIPasteboard.general.string = note.ocrRawText
    }

    var decodedEntities: LLMNoteSummary.Entities? {
        note.decodedEntities
    }

    var hasEntities: Bool {
        guard let e = decodedEntities else { return false }
        return !e.people.isEmpty || !e.dates.isEmpty || !e.amounts.isEmpty || !e.links.isEmpty
    }
}
