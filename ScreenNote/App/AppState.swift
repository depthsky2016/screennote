import Foundation
import Observation
import SwiftData

@MainActor
@Observable
final class AppState {
    var toastMessage: String?
    var pendingScreenshotEvent = false
    var silentModeEnabled = false
    var apiKeyConfigured = false
    var notesRefreshToken = 0
    var deepLinkNoteID: UUID?

    let settingsStore = SettingsStore()
    let keychainService = KeychainService()
    let screenshotMonitor = ScreenshotMonitor()

    private(set) var noteRepository: NoteRepository?
    private(set) var tagRepository: TagRepository?
    private(set) var folderRepository: FolderRepository?
    private(set) var processingPipeline: NoteProcessingPipeline?

    func configureRepositories(modelContext: ModelContext) {
        guard noteRepository == nil else { return }
        let imageProcessor = ImageProcessor()
        let spotlightService = SpotlightService()
        noteRepository = NoteRepository(
            modelContext: modelContext,
            imageProcessor: imageProcessor,
            spotlightService: spotlightService
        )
        tagRepository = TagRepository(modelContext: modelContext)
        folderRepository = FolderRepository(modelContext: modelContext)
        processingPipeline = NoteProcessingPipeline(
            modelContext: modelContext,
            ocrService: OCRService(),
            llmService: KimiLLMService(),
            imageProcessor: imageProcessor,
            spotlightService: spotlightService
        )
    }

    func bootstrap() async {
        bootstrapAPIKeyIfNeeded()
        silentModeEnabled = settingsStore.isSilentModeEnabled
        apiKeyConfigured = (try? keychainService.readKey())?.isEmpty == false
        screenshotMonitor.startMonitoring { [weak self] in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.pendingScreenshotEvent = true
                if !self.silentModeEnabled {
                    self.toastMessage = "检测到截图，请从相册导入最新截图。"
                }
            }
        }
    }

    func updateSilentMode(_ enabled: Bool) {
        silentModeEnabled = enabled
        settingsStore.isSilentModeEnabled = enabled
    }

    func refreshAPIKeyStatus() {
        apiKeyConfigured = (try? keychainService.readKey())?.isEmpty == false
    }

    func showToast(_ message: String) {
        toastMessage = message
    }

    func clearToast() {
        toastMessage = nil
    }

    func requestNotesRefresh() {
        notesRefreshToken += 1
    }

    private func bootstrapAPIKeyIfNeeded() {
        let environment = ProcessInfo.processInfo.environment
        guard let bootstrappedKey = environment["SCREENNOTE_BOOTSTRAP_KIMI_KEY"]?
            .trimmingCharacters(in: .whitespacesAndNewlines),
              !bootstrappedKey.isEmpty
        else {
            return
        }

        guard (try? keychainService.readKey()) == nil else {
            return
        }

        try? keychainService.saveKey(bootstrappedKey)
    }
}
