import Foundation
import SwiftData
import UIKit

@Model
final class Note {
    var id: UUID
    @Attribute(.externalStorage) var imageData: Data
    @Attribute(.externalStorage) var thumbnailData: Data?
    var ocrRawText: String
    var aiTitle: String
    var aiSummary: String
    var userNote: String
    @Relationship(inverse: \Tag.notes) var tags: [Tag]
    @Relationship(inverse: \NoteFolder.notes) var folder: NoteFolder?
    var processingStatusRawValue: String
    var sourceApp: String?
    var createdAt: Date
    var updatedAt: Date
    var isPinned: Bool
    var isArchived: Bool
    var imageHash: String
    var entitiesJSON: String

    var processingStatus: ProcessingStatus {
        get { ProcessingStatus(rawValue: processingStatusRawValue) ?? .pending }
        set { processingStatusRawValue = newValue.rawValue }
    }

    var decodedEntities: LLMNoteSummary.Entities? {
        guard !entitiesJSON.isEmpty else { return nil }
        return try? JSONDecoder().decode(LLMNoteSummary.Entities.self, from: Data(entitiesJSON.utf8))
    }

    init(
        id: UUID = UUID(),
        imageData: Data,
        thumbnailData: Data? = nil,
        ocrRawText: String = "",
        aiTitle: String = "",
        aiSummary: String = "",
        userNote: String = "",
        tags: [Tag] = [],
        folder: NoteFolder? = nil,
        processingStatus: ProcessingStatus = .pending,
        sourceApp: String? = nil,
        createdAt: Date = .now,
        updatedAt: Date = .now,
        isPinned: Bool = false,
        isArchived: Bool = false,
        imageHash: String = "",
        entitiesJSON: String = ""
    ) {
        self.id = id
        self.imageData = imageData
        self.thumbnailData = thumbnailData
        self.ocrRawText = ocrRawText
        self.aiTitle = aiTitle
        self.aiSummary = aiSummary
        self.userNote = userNote
        self.tags = tags
        self.folder = folder
        self.processingStatusRawValue = processingStatus.rawValue
        self.sourceApp = sourceApp
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isPinned = isPinned
        self.isArchived = isArchived
        self.imageHash = imageHash
        self.entitiesJSON = entitiesJSON
    }
}

extension Note {
    static var mockCompleted: Note {
        let note = Note(
            imageData: UIImage.previewPlaceholder.jpegData(compressionQuality: 0.8) ?? Data(),
            thumbnailData: UIImage.previewPlaceholder.jpegData(compressionQuality: 0.6),
            ocrRawText: "会议主题：Q2 产品规划\n下周完成需求评审",
            aiTitle: "Q2 产品规划",
            aiSummary: "团队讨论了下一季度的三个关键项目，优先级集中在导入、搜索和智能摘要体验优化。",
            userNote: "重点跟进搜索排序。",
            processingStatus: .completed,
            imageHash: UUID().uuidString
        )
        note.tags = [
            Tag(name: "工作/会议", color: "#3498DB", icon: "briefcase", isSystem: true),
            Tag(name: "产品/UI", color: "#9B59B6", icon: "app.badge", isSystem: true)
        ]
        return note
    }

    static var mockProcessing: Note {
        Note(
            imageData: UIImage.previewPlaceholder.jpegData(compressionQuality: 0.8) ?? Data(),
            thumbnailData: UIImage.previewPlaceholder.jpegData(compressionQuality: 0.6),
            aiTitle: "聊天截图",
            aiSummary: "正在整理截图内容...",
            processingStatus: .llmProcessing,
            imageHash: UUID().uuidString
        )
    }

    static var mockFailed: Note {
        Note(
            imageData: UIImage.previewPlaceholder.jpegData(compressionQuality: 0.8) ?? Data(),
            thumbnailData: UIImage.previewPlaceholder.jpegData(compressionQuality: 0.6),
            aiTitle: "识别失败",
            aiSummary: "Kimi API 调用失败，请检查网络或 API Key。",
            processingStatus: .failed,
            imageHash: UUID().uuidString
        )
    }
}
