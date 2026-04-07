import Foundation
import SwiftData
import UIKit

enum NoteSortOption: String, CaseIterable, Identifiable {
    case newest
    case oldest
    case pinnedFirst

    var id: String { rawValue }
}

enum NoteFilter: Equatable {
    case all
    case active
    case archived
    case tag(String)
    case folder(String)
}

@MainActor
protocol NoteRepositoryProtocol {
    func fetchNotes(sortBy: NoteSortOption, filter: NoteFilter) throws -> [Note]
    func createNote(from imageData: Data) async throws -> Note
    func updateNote(_ note: Note) throws
    func archiveNote(_ note: Note) throws
    func deleteNotePermanently(_ note: Note) throws
    func searchNotes(query: String) throws -> [Note]
    func ensureSeedTags() throws
}

@MainActor
final class NoteRepository: NoteRepositoryProtocol {
    private let modelContext: ModelContext
    private let imageProcessor: ImageProcessorProtocol
    private let spotlightService: SpotlightServiceProtocol

    init(
        modelContext: ModelContext,
        imageProcessor: ImageProcessorProtocol,
        spotlightService: SpotlightServiceProtocol
    ) {
        self.modelContext = modelContext
        self.imageProcessor = imageProcessor
        self.spotlightService = spotlightService
    }

    func fetchNotes(sortBy: NoteSortOption = .newest, filter: NoteFilter = .active) throws -> [Note] {
        var descriptor = FetchDescriptor<Note>()

        switch filter {
        case .all:
            break
        case .active:
            descriptor.predicate = #Predicate<Note> { !$0.isArchived }
        case .archived:
            descriptor.predicate = #Predicate<Note> { $0.isArchived }
        case .tag, .folder:
            // iOS 17 #Predicate 不支持关系集合查询，先取活跃笔记再内存过滤
            descriptor.predicate = #Predicate<Note> { !$0.isArchived }
        }

        switch sortBy {
        case .newest, .pinnedFirst:
            descriptor.sortBy = [SortDescriptor(\.createdAt, order: .reverse)]
        case .oldest:
            descriptor.sortBy = [SortDescriptor(\.createdAt, order: .forward)]
        }

        var notes = try modelContext.fetch(descriptor)

        // pinnedFirst 需要内存二次排序（SwiftData SortDescriptor 不支持 Bool）
        if sortBy == .pinnedFirst {
            notes.sort {
                if $0.isPinned == $1.isPinned { return $0.createdAt > $1.createdAt }
                return $0.isPinned && !$1.isPinned
            }
        }

        // 关系查询的内存过滤
        switch filter {
        case .tag(let name):
            notes = notes.filter { $0.tags.contains { $0.name == name } }
        case .folder(let name):
            notes = notes.filter { $0.folder?.name == name }
        default:
            break
        }

        return notes
    }

    func createNote(from imageData: Data) async throws -> Note {
        let processed = try imageProcessor.prepareImageData(imageData)

        // 用 predicate 去重，避免全量加载
        let hashValue = processed.hash
        var dedupDescriptor = FetchDescriptor<Note>(predicate: #Predicate<Note> { $0.imageHash == hashValue })
        dedupDescriptor.fetchLimit = 1
        if let duplicate = try modelContext.fetch(dedupDescriptor).first {
            return duplicate
        }

        let note = Note(
            imageData: processed.imageData,
            thumbnailData: processed.thumbnailData,
            processingStatus: .pending,
            imageHash: processed.hash
        )
        modelContext.insert(note)
        try modelContext.save()
        return note
    }

    func updateNote(_ note: Note) throws {
        note.updatedAt = .now
        try modelContext.save()
        Task {
            await spotlightService.index(note: note)
        }
    }

    func archiveNote(_ note: Note) throws {
        note.isArchived = true
        note.updatedAt = .now
        try modelContext.save()
    }

    func deleteNotePermanently(_ note: Note) throws {
        let noteID = note.id
        modelContext.delete(note)
        try modelContext.save()
        Task {
            await spotlightService.remove(noteID: noteID)
        }
    }

    func searchNotes(query: String) throws -> [Note] {
        let normalized = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !normalized.isEmpty else {
            return try fetchNotes(sortBy: .pinnedFirst, filter: .active)
        }

        let notes = try fetchNotes(sortBy: .pinnedFirst, filter: .active)
        return notes
            .compactMap { note -> (Note, Int)? in
                var score = 0
                if note.aiTitle.lowercased().contains(normalized) { score += 100 }
                if note.aiSummary.lowercased().contains(normalized) { score += 60 }
                if note.ocrRawText.lowercased().contains(normalized) { score += 40 }
                if note.userNote.lowercased().contains(normalized) { score += 20 }
                if note.tags.contains(where: { $0.name.lowercased().contains(normalized) }) { score += 10 }
                return score > 0 ? (note, score) : nil
            }
            .sorted { $0.1 > $1.1 }
            .map(\.0)
    }

    func ensureSeedTags() throws {
        let existing = try modelContext.fetch(FetchDescriptor<Tag>())
        guard existing.isEmpty else { return }

        Constants.seedTags.forEach { seed in
            modelContext.insert(Tag(name: seed.name, color: seed.color, icon: seed.icon, isSystem: true))
        }
        try modelContext.save()
    }
}
