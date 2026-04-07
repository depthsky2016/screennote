import Foundation

@MainActor
final class SettingsStore {
    private enum Keys {
        static let silentModeEnabled = "silent_mode_enabled"
    }

    var isSilentModeEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: Keys.silentModeEnabled) }
        set { UserDefaults.standard.set(newValue, forKey: Keys.silentModeEnabled) }
    }
}
