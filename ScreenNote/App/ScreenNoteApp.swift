import CoreSpotlight
import SwiftData
import SwiftUI

@main
struct ScreenNoteApp: App {
    @State private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
                .task {
                    await appState.bootstrap()
                }
                .onContinueUserActivity(CSSearchableItemActionType) { activity in
                    guard let identifier = activity.userInfo?[CSSearchableItemActivityIdentifier] as? String,
                          let uuid = UUID(uuidString: identifier) else { return }
                    appState.deepLinkNoteID = uuid
                }
        }
        .modelContainer(for: [Note.self, Tag.self, NoteFolder.self])
    }
}
