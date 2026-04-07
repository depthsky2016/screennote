import SwiftUI
import SwiftData
import OSLog

struct ContentView: View {
    private let logger = Logger(subsystem: "com.jiangfyi.screennote", category: "bootstrap")
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    @State private var didRunBootstrapImport = false
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false

    var body: some View {
        TabView {
            NoteListView()
                .tabItem {
                    Label("首页", systemImage: "house.fill")
                }

            SearchView()
                .tabItem {
                    Label("搜索", systemImage: "magnifyingglass")
                }

            SettingsView()
                .tabItem {
                    Label("设置", systemImage: "gearshape")
                }
        }
        .overlay(alignment: .bottom) {
            if let toastMessage = appState.toastMessage {
                Text(toastMessage)
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(.black.opacity(0.82), in: Capsule())
                    .padding(.bottom, 24)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .task {
                        try? await Task.sleep(for: .seconds(2))
                        appState.clearToast()
                    }
            }
        }
        .fullScreenCover(isPresented: Binding(
            get: { !hasSeenOnboarding },
            set: { newValue in hasSeenOnboarding = !newValue }
        )) {
            OnboardingView()
        }
        .animation(.easeInOut(duration: 0.2), value: appState.toastMessage)
        .task {
            guard !didRunBootstrapImport else { return }
            didRunBootstrapImport = true
            appState.configureRepositories(modelContext: modelContext)
            await bootstrapImportsIfNeeded()
        }
    }

    @MainActor
    private func bootstrapImportsIfNeeded() async {
        let environment = ProcessInfo.processInfo.environment
        guard let importDirectory = environment["SCREENNOTE_BOOTSTRAP_IMPORT_DIR"],
              !importDirectory.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else {
            logger.log("Bootstrap import skipped: no import directory in environment")
            appendBootstrapDiagnostic("Bootstrap import skipped: no import directory in environment")
            return
        }

        let directoryURL = URL(filePath: importDirectory)
        logger.log("Bootstrap import started from directory: \(directoryURL.path(percentEncoded: false), privacy: .public)")
        appendBootstrapDiagnostic("Bootstrap import started from directory: \(directoryURL.path(percentEncoded: false))")
        guard let repository = appState.noteRepository else { return }

        let fileURLs = (try? FileManager.default.contentsOfDirectory(
            at: directoryURL,
            includingPropertiesForKeys: nil
        ))?
        .filter { url in
            ["png", "jpg", "jpeg", "heic"].contains(url.pathExtension.lowercased())
        }
        .sorted { $0.lastPathComponent < $1.lastPathComponent } ?? []

        guard !fileURLs.isEmpty else {
            logger.error("Bootstrap import found no image files")
            appendBootstrapDiagnostic("Bootstrap import found no image files")
            appState.showToast("未发现可导入的测试截图。")
            return
        }

        logger.log("Bootstrap import discovered \(fileURLs.count) files")
        appendBootstrapDiagnostic("Bootstrap import discovered \(fileURLs.count) files")
        var importedCount = 0
        for fileURL in fileURLs {
            do {
                let data = try Data(contentsOf: fileURL)
                let note = try await repository.createNote(from: data)
                Task { await appState.processingPipeline?.process(note) }
                importedCount += 1
                logger.log("Bootstrap import succeeded for \(fileURL.lastPathComponent, privacy: .public)")
                appendBootstrapDiagnostic("Bootstrap import succeeded for \(fileURL.lastPathComponent)")
            } catch {
                logger.error("Bootstrap import failed for \(fileURL.lastPathComponent, privacy: .public): \(error.localizedDescription, privacy: .public)")
                appendBootstrapDiagnostic("Bootstrap import failed for \(fileURL.lastPathComponent): \(error.localizedDescription)")
            }
        }

        appState.requestNotesRefresh()
        logger.log("Bootstrap import finished with \(importedCount) successful items")
        appendBootstrapDiagnostic("Bootstrap import finished with \(importedCount) successful items")
        appState.showToast("已导入 \(importedCount) / \(fileURLs.count) 张测试截图。")
    }

    private func appendBootstrapDiagnostic(_ message: String) {
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return
        }

        let diagnosticURL = documentsDirectory.appending(path: "bootstrap-diagnostics.log")
        let line = "\(Date().ISO8601Format()) \(message)\n"
        let data = Data(line.utf8)

        if FileManager.default.fileExists(atPath: diagnosticURL.path(percentEncoded: false)) {
            if let handle = try? FileHandle(forWritingTo: diagnosticURL) {
                defer { try? handle.close() }
                try? handle.seekToEnd()
                try? handle.write(contentsOf: data)
            }
        } else {
            try? data.write(to: diagnosticURL)
        }
    }
}
