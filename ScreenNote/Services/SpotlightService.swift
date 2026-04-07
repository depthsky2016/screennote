import CoreSpotlight
import Foundation
import MobileCoreServices
import OSLog

protocol SpotlightServiceProtocol {
    func index(note: Note) async
    func remove(noteID: UUID) async
}

struct SpotlightService: SpotlightServiceProtocol {
    private let logger = Logger(subsystem: "com.jiangfyi.screennote", category: "spotlight")

    func index(note: Note) async {
        let attributes = CSSearchableItemAttributeSet(contentType: .text)
        attributes.title = note.aiTitle
        attributes.contentDescription = note.aiSummary
        attributes.thumbnailData = note.thumbnailData
        attributes.keywords = note.tags.map(\.name)

        let item = CSSearchableItem(
            uniqueIdentifier: note.id.uuidString,
            domainIdentifier: "com.jiangfyi.screennote.note",
            attributeSet: attributes
        )

        do {
            try await CSSearchableIndex.default().indexSearchableItems([item])
            logger.info("Indexed note \(note.id.uuidString)")
        } catch {
            logger.error("Failed to index note \(note.id.uuidString): \(error.localizedDescription)")
        }
    }

    func remove(noteID: UUID) async {
        do {
            try await CSSearchableIndex.default().deleteSearchableItems(withIdentifiers: [noteID.uuidString])
            logger.info("Removed note \(noteID.uuidString) from index")
        } catch {
            logger.error("Failed to remove note \(noteID.uuidString) from index: \(error.localizedDescription)")
        }
    }
}
