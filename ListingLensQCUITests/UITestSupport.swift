import XCTest

/// Shared launch helpers. Every test launches with `-UITestReset` (clears persisted
/// theme/accent/language so each test starts from a known state) and, where a
/// deterministic photo batch is needed, `-UITestFixtureBatch <name>` (see
/// `ListingLensQC/App/UITestFixtures.swift` for the batches this understands:
/// `mixed10`, `stress20`, `duplicates`). Both flags are `#if DEBUG`-gated in the app
/// and compiled out of Release entirely.
enum UITestLaunch {
    static func app(fixtureBatch: String? = nil, extraArguments: [String] = []) -> XCUIApplication {
        let app = XCUIApplication()
        var args = ["-UITestReset"]
        if let fixtureBatch {
            args += ["-UITestFixtureBatch", fixtureBatch]
        }
        app.launchArguments = args + extraArguments
        return app
    }

    /// Attaches a screenshot of the given element (or the whole screen) to the test
    /// report, named for later retrieval via `xcrun xcresulttool` or Xcode's report
    /// navigator - this is the "screenshot automation" path: run the suite, then
    /// pull named attachments out of the .xcresult bundle.
    static func attachScreenshot(_ name: String, of element: XCUIElement, in test: XCTestCase) {
        let attachment = XCTAttachment(screenshot: element.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        test.add(attachment)
    }
}

extension XCUIApplication {
    /// SwiftUI doesn't guarantee a stable XCUIElement `.elementType` for a given
    /// control (a `NavigationLink` label can surface as `.button` or `.link`
    /// depending on context) - look up by accessibility identifier across any type
    /// instead of guessing the type.
    func anyElement(_ identifier: String) -> XCUIElement {
        descendants(matching: .any).matching(identifier: identifier).firstMatch
    }

    /// SwiftUI's `LazyVGrid`/`List` only realize on-screen rows into the accessibility
    /// tree, so a single snapshot undercounts a long batch - and nested
    /// `.accessibilityElement(children: .combine)` containers can make XCUITest
    /// report the *same* logical row's identifier more than once, sometimes
    /// concatenated with itself. This scrolls (swiping the whole window, since the
    /// active scrollable's XCUIElement type varies between a `List` and a
    /// `LazyVGrid`/`ScrollView`) and canonicalizes each match down to the first
    /// `prefix<rest-up-to-next-dash-run>` token so duplicate/concatenated
    /// observations of the same row collapse to one.
    func collectIdentifiers(prefix: String, maxScrolls: Int = 14) -> Set<String> {
        var seen = Set<String>()
        var lastCount = -1
        var attempts = 0
        let window = windows.firstMatch
        while attempts < maxScrolls {
            let matches = descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH %@", prefix))
            for element in matches.allElementsBoundByIndex {
                let raw = element.identifier
                guard raw.hasPrefix(prefix) else { continue }
                let rest = raw.dropFirst(prefix.count)
                let canonical = rest.split(separator: "-").first.map { String($0) } ?? String(rest)
                seen.insert(prefix + canonical)
            }
            if seen.count == lastCount { break }
            lastCount = seen.count
            window.swipeUp()
            attempts += 1
        }
        return seen
    }
}
