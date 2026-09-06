#if DEBUG
import Foundation

/// UI-test-only determinism helper: clears persisted theme/accent/language
/// preferences so a UI test run starts from a known state regardless of what a
/// previous manual QA session (or a previous test) left in `UserDefaults` on this
/// simulator. `#if DEBUG`-gated the same way as `UITestFixtures.swift` - compiled
/// out of Release entirely.
enum UITestSupport {
    static let resetLaunchArgument = "-UITestReset"

    static func resetStateIfRequested() {
        guard ProcessInfo.processInfo.arguments.contains(resetLaunchArgument) else { return }
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: "listinglensqc.appearance")
        defaults.removeObject(forKey: "listinglensqc.accent")
        defaults.removeObject(forKey: "LocalizationKit.selectedLocaleID")
    }
}
#endif
