import Foundation
import Observation

@MainActor
@Observable
final class SettingsViewModel {
    var apiKey = ""
    var validationMessage = ""

    private let keychainService: KeychainService

    init(keychainService: KeychainService = .init()) {
        self.keychainService = keychainService
        apiKey = (try? keychainService.readKey()) ?? ""
    }

    func saveAPIKey() {
        do {
            try keychainService.saveKey(apiKey.trimmingCharacters(in: .whitespacesAndNewlines))
            validationMessage = "Kimi API Key 已保存。"
        } catch {
            validationMessage = "保存失败：\(error.localizedDescription)"
        }
    }

    func deleteAPIKey() {
        do {
            try keychainService.deleteKey()
            apiKey = ""
            validationMessage = "Kimi API Key 已删除。"
        } catch {
            validationMessage = "删除失败：\(error.localizedDescription)"
        }
    }
}
