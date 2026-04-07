import Foundation
import Testing
@testable import ScreenNote

struct ScreenNoteTests {
    @Test
    func kimiRequestPayloadUsesJSONMode() throws {
        let service = KimiLLMService(
            keychainService: KeychainService(),
            session: .shared,
            configurationBuilder: { _ in
                KimiConfiguration(
                    baseURL: URL(string: "https://api.moonshot.cn/v1")!,
                    model: "kimi-k2.5",
                    apiKey: "test-key",
                    timeout: 15
                )
            }
        )

        let request = try service.buildRequest(
            configuration: .default(apiKey: "test-key"),
            ocrText: "hello world"
        )

        #expect(request.url?.absoluteString == "https://api.moonshot.cn/v1/chat/completions")
        let body = try JSONSerialization.jsonObject(with: request.httpBody ?? Data()) as? [String: Any]
        let responseFormat = body?["response_format"] as? [String: Any]
        #expect(responseFormat?["type"] as? String == "json_object")
    }

    @Test
    func chunkedKeepsOrder() {
        let result = [1, 2, 3, 4, 5].chunked(into: 2)
        #expect(result.count == 3)
        #expect(result[0] == [1, 2])
        #expect(result[2] == [5])
    }
}
