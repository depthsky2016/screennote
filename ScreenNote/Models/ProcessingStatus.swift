import Foundation

enum ProcessingStatus: String, Codable, CaseIterable, Sendable {
    case pending
    case ocrProcessing
    case ocrDone
    case ocrDoneButLLMFailed
    case llmProcessing
    case completed
    case failed

    var displayText: String {
        switch self {
        case .pending: "等待处理"
        case .ocrProcessing: "识别文字中"
        case .ocrDone: "等待摘要"
        case .ocrDoneButLLMFailed: "OCR 完成但摘要失败"
        case .llmProcessing: "AI 总结中"
        case .completed: "已完成"
        case .failed: "处理失败"
        }
    }

    var canRetry: Bool {
        self == .failed || self == .ocrDoneButLLMFailed
    }
}
