import Foundation
import Security

struct KeychainService {
    private let service = "com.jiangfyi.screennote.kimi"
    private let account = "kimi_api_key"

    func saveKey(_ key: String) throws {
        let data = Data(key.utf8)
        let query = baseQuery
        SecItemDelete(query as CFDictionary)
        let attributes = query.merging([kSecValueData as String: data]) { _, new in new }
        let status = SecItemAdd(attributes as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.unhandledError(status)
        }
    }

    func readKey() throws -> String {
        let query = baseQuery.merging([
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]) { _, new in new }
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status != errSecItemNotFound else {
            throw LLMError.missingAPIKey
        }
        guard status == errSecSuccess, let data = result as? Data, let key = String(data: data, encoding: .utf8) else {
            throw KeychainError.unhandledError(status)
        }
        return key
    }

    func deleteKey() throws {
        let status = SecItemDelete(baseQuery as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unhandledError(status)
        }
    }

    private var baseQuery: [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
    }
}
