import Foundation

enum UserNotificationCenterSupport {
    static var canUseCurrentCenter: Bool {
        self.isAppBundle(Bundle.main.bundleURL)
    }

    static func isAppBundle(_ bundleURL: URL) -> Bool {
        bundleURL.pathExtension.lowercased() == "app"
    }
}
