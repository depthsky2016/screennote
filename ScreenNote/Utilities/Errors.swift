import Foundation

enum OCRError: LocalizedError {
    case invalidImage

    var errorDescription: String? {
        switch self {
        case .invalidImage: "无法读取图片内容。"
        }
    }
}

enum LLMError: LocalizedError {
    case missingAPIKey
    case invalidResponse
    case timeout
    case rateLimited
    case authenticationFailed
    case parsingFailed(raw: String)
    case serverError(code: Int)

    var errorDescription: String? {
        switch self {
        case .missingAPIKey: "未配置 Kimi API Key，请先前往设置页。"
        case .invalidResponse: "Kimi API 返回了无效响应。"
        case .timeout: "Kimi API 请求超时。"
        case .rateLimited: "Kimi API 限流，请稍后重试。"
        case .authenticationFailed: "Kimi API Key 无效或鉴权失败。"
        case .parsingFailed(let raw): "Kimi 响应解析失败：\(raw)"
        case .serverError(let code): "Kimi API 错误，状态码 \(code)。"
        }
    }
}

enum ImageProcessingError: LocalizedError {
    case compressionFailed

    var errorDescription: String? {
        switch self {
        case .compressionFailed: "图片压缩失败。"
        }
    }
}

enum KeychainError: Error {
    case unhandledError(OSStatus)
}
