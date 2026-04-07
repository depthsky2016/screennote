import Foundation
import UIKit

@MainActor
final class ScreenshotMonitor {
    private var observer: NSObjectProtocol?

    func startMonitoring(handler: @escaping @MainActor () -> Void) {
        guard observer == nil else { return }
        observer = NotificationCenter.default.addObserver(
            forName: UIApplication.userDidTakeScreenshotNotification,
            object: nil,
            queue: .main
        ) { _ in
            Task { @MainActor in
                handler()
            }
        }
    }

    deinit {
        if let observer {
            NotificationCenter.default.removeObserver(observer)
        }
    }
}
