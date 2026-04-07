import Foundation

struct LLMNoteSummary: Codable, Equatable, Sendable {
    struct Entities: Codable, Equatable, Sendable {
        var people: [String]
        var dates: [String]
        var amounts: [String]
        var links: [String]
    }

    var title: String
    var summary: String
    var tags: [String]
    var entities: Entities
    var contentType: String

    enum CodingKeys: String, CodingKey {
        case title
        case summary
        case tags
        case entities
        case contentType = "content_type"
    }
}

struct KimiConfiguration: Equatable, Sendable {
    var baseURL: URL
    var model: String
    var apiKey: String
    var timeout: TimeInterval

    static func `default`(apiKey: String) -> KimiConfiguration {
        KimiConfiguration(
            baseURL: URL(string: "https://api.moonshot.cn/v1")!,
            model: "kimi-k2.5",
            apiKey: apiKey,
            timeout: 30
        )
    }
}

protocol LLMServiceProtocol {
    func generateSummary(ocrText: String) async throws -> LLMNoteSummary
    func validateConfiguration() async throws
}

struct KimiLLMService: LLMServiceProtocol {
    private let keychainService: KeychainService
    private let session: URLSession
    private let configurationBuilder: (String) -> KimiConfiguration

    init(
        keychainService: KeychainService = .init(),
        session: URLSession = .shared,
        configurationBuilder: @escaping (String) -> KimiConfiguration = KimiConfiguration.default(apiKey:)
    ) {
        self.keychainService = keychainService
        self.session = session
        self.configurationBuilder = configurationBuilder
    }

    func validateConfiguration() async throws {
        guard let apiKey = try? keychainService.readKey(), !apiKey.isEmpty else {
            throw LLMError.missingAPIKey
        }
    }

    func generateSummary(ocrText: String) async throws -> LLMNoteSummary {
        let apiKey = try keychainService.readKey()
        let configuration = configurationBuilder(apiKey)
        let request = try buildRequest(configuration: configuration, ocrText: ocrText)

        var latestError: Error?
        let maxRetries = 3
        for attempt in 0..<maxRetries {
            do {
                let (data, response) = try await session.data(for: request)
                return try decodeSummary(data: data, response: response)
            } catch let error as LLMError {
                // 不可重试的错误：立即抛出
                switch error {
                case .authenticationFailed, .missingAPIKey, .parsingFailed:
                    throw error
                case .rateLimited:
                    // 指数退避：2s, 4s, 8s
                    let delay = pow(2.0, Double(attempt)) * 2.0
                    try? await Task.sleep(for: .seconds(delay))
                    latestError = error
                case .timeout, .serverError, .invalidResponse:
                    // 指数退避：1s, 2s, 4s
                    let delay = pow(2.0, Double(attempt)) * 1.0
                    try? await Task.sleep(for: .seconds(delay))
                    latestError = error
                }
            } catch {
                // 网络错误等：指数退避 1s, 2s, 4s
                let delay = pow(2.0, Double(attempt)) * 1.0
                try? await Task.sleep(for: .seconds(delay))
                latestError = error
            }
        }

        throw latestError ?? LLMError.invalidResponse
    }

    private func buildRequest(configuration: KimiConfiguration, ocrText: String) throws -> URLRequest {
        let url = configuration.baseURL.appending(path: "chat/completions")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = configuration.timeout
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(configuration.apiKey)", forHTTPHeaderField: "Authorization")

        let payload = KimiChatRequest(
            model: configuration.model,
            temperature: configuration.model == "kimi-k2.5" ? nil : 0.3,
            n: configuration.model == "kimi-k2.5" ? nil : 1,
            responseFormat: .init(type: "json_object"),
            messages: [
                .init(role: "system", content: Constants.kimiSystemPrompt),
                .init(role: "user", content: Constants.kimiUserPrompt(ocrText: ocrText))
            ]
        )
        request.httpBody = try JSONEncoder().encode(payload)
        return request
    }

    private func decodeSummary(data: Data, response: URLResponse) throws -> LLMNoteSummary {
        guard let response = response as? HTTPURLResponse else {
            throw LLMError.invalidResponse
        }

        switch response.statusCode {
        case 200:
            let chatResponse = try JSONDecoder().decode(KimiChatResponse.self, from: data)
            guard let content = chatResponse.choices.first?.message.content, !content.isEmpty else {
                throw LLMError.invalidResponse
            }
            do {
                return try JSONDecoder().decode(LLMNoteSummary.self, from: Data(content.utf8))
            } catch {
                throw LLMError.parsingFailed(raw: content)
            }
        case 401:
            throw LLMError.authenticationFailed
        case 429:
            throw LLMError.rateLimited
        case 504:
            throw LLMError.timeout
        default:
            throw LLMError.serverError(code: response.statusCode)
        }
    }
}

struct KimiChatRequest: Encodable, Equatable {
    struct Message: Encodable, Equatable {
        let role: String
        let content: String
    }

    struct ResponseFormat: Encodable, Equatable {
        let type: String

        enum CodingKeys: String, CodingKey {
            case type
        }
    }

    let model: String
    let temperature: Double?
    let n: Int?
    let responseFormat: ResponseFormat
    let messages: [Message]

    enum CodingKeys: String, CodingKey {
        case model
        case temperature
        case n
        case responseFormat = "response_format"
        case messages
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(model, forKey: .model)
        try container.encodeIfPresent(temperature, forKey: .temperature)
        try container.encodeIfPresent(n, forKey: .n)
        try container.encode(responseFormat, forKey: .responseFormat)
        try container.encode(messages, forKey: .messages)
    }
}

private struct KimiChatResponse: Decodable {
    struct Choice: Decodable {
        struct Message: Decodable {
            let content: String?
        }
        let message: Message
    }

    let choices: [Choice]
}
