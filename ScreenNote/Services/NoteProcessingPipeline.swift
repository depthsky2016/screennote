import Foundation
import SwiftData

@MainActor
final class NoteProcessingPipeline {
    private let modelContext: ModelContext
    private let ocrService: OCRServiceProtocol
    private let llmService: LLMServiceProtocol
    private let imageProcessor: ImageProcessorProtocol
    private let spotlightService: SpotlightServiceProtocol

    init(
        modelContext: ModelContext,
        ocrService: OCRServiceProtocol,
        llmService: LLMServiceProtocol,
        imageProcessor: ImageProcessorProtocol,
        spotlightService: SpotlightServiceProtocol
    ) {
        self.modelContext = modelContext
        self.ocrService = ocrService
        self.llmService = llmService
        self.imageProcessor = imageProcessor
        self.spotlightService = spotlightService
    }

    func process(_ note: Note) async {
        do {
            // OCR 阶段（如果已完成则跳过）
            if note.processingStatus.canRetry || note.processingStatus == .pending {
                if note.ocrRawText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    note.processingStatus = .ocrProcessing
                    try modelContext.save()

                    let image = try imageProcessor.decodeImage(data: note.imageData)
                    note.ocrRawText = try await ocrService.recognizeText(from: image)
                    note.processingStatus = .ocrDone
                    note.updatedAt = .now
                    try modelContext.save()
                } else if note.processingStatus != .ocrDoneButLLMFailed {
                    note.processingStatus = .ocrDone
                    try modelContext.save()
                }
            }

            // 空文本快速完成
            guard !note.ocrRawText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                note.aiTitle = "无文字内容的截图"
                note.aiSummary = "截图内没有识别到可用于总结的文字内容。"
                note.processingStatus = .completed
                try modelContext.save()
                return
            }

            // LLM 阶段
            try await llmService.validateConfiguration()
            note.processingStatus = .llmProcessing
            try modelContext.save()

            let summary = try await llmService.generateSummary(ocrText: note.ocrRawText)
            note.aiTitle = summary.title
            note.aiSummary = summary.summary
            note.updatedAt = .now
            note.tags = try mergeTags(names: summary.tags)

            // 持久化 entities
            if let data = try? JSONEncoder().encode(summary.entities) {
                note.entitiesJSON = String(data: data, encoding: .utf8) ?? ""
            }

            note.processingStatus = .completed
            try modelContext.save()
            await spotlightService.index(note: note)
        } catch {
            note.aiSummary = error.localizedDescription
            note.updatedAt = .now
            // 区分：OCR 已完成但 LLM 失败 vs 全流程失败
            if note.processingStatus == .llmProcessing || note.processingStatus == .ocrDone || note.processingStatus == .ocrDoneButLLMFailed {
                note.processingStatus = .ocrDoneButLLMFailed
            } else {
                note.processingStatus = .failed
            }
            try? modelContext.save()
        }
    }

    private func mergeTags(names: [String]) throws -> [Tag] {
        let normalized = names.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        let existingTags = try modelContext.fetch(FetchDescriptor<Tag>())
        var result: [Tag] = []
        var needsSave = false

        for name in normalized {
            if let tag = existingTags.first(where: { $0.name == name }) {
                result.append(tag)
            } else {
                let defaultSeed = Constants.seedTags.first { $0.name == name }
                let tag = Tag(
                    name: name,
                    color: defaultSeed?.color ?? "#95A5A6",
                    icon: defaultSeed?.icon ?? "tag",
                    isSystem: defaultSeed != nil
                )
                modelContext.insert(tag)
                result.append(tag)
                needsSave = true
            }
        }

        if needsSave {
            try modelContext.save()
        }
        return result
    }
}
