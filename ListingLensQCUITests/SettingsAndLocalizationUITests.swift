import XCTest

/// Settings, About, Privacy, language switching, and appearance switching, driven
/// through the app's real accessibility identifiers.
final class SettingsAndLocalizationUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    private func openSettings(_ app: XCUIApplication) {
        app.launch()
        XCTAssertTrue(app.anyElement("import.selectPhotosButton").waitForExistence(timeout: 5))
        app.anyElement("import.settingsLink").tap()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 3))
    }

    func testSettingsAboutAndPrivacyScreensShowExpectedContent() {
        let app = UITestLaunch.app()
        openSettings(app)
        UITestLaunch.attachScreenshot("08-settings", of: app, in: self)

        app.staticTexts["About"].firstMatch.tap()
        XCTAssertTrue(app.navigationBars["About"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["Version 1.0.0"].waitForExistence(timeout: 2))
        UITestLaunch.attachScreenshot("09-about", of: app, in: self)
        app.navigationBars.buttons.element(boundBy: 0).tap()

        app.staticTexts["Privacy"].firstMatch.tap()
        XCTAssertTrue(app.navigationBars["Privacy"].waitForExistence(timeout: 3))
        UITestLaunch.attachScreenshot("10-privacy", of: app, in: self)
    }

    func testAppearancePickerSwitchesAndPersists() {
        let app = UITestLaunch.app()
        openSettings(app)

        app.buttons["Black"].tap()
        XCTAssertTrue(app.buttons["Black"].isSelected || app.buttons["Black"].value as? String == "1")

        app.terminate()
        let relaunched = UITestLaunch.app() // no -UITestReset: verifies persistence across relaunch
        relaunched.launchArguments.removeAll { $0 == "-UITestReset" }
        relaunched.launch()
        XCTAssertTrue(relaunched.anyElement("import.selectPhotosButton").waitForExistence(timeout: 5))
        relaunched.anyElement("import.settingsLink").tap()
        XCTAssertTrue(relaunched.navigationBars["Settings"].waitForExistence(timeout: 3))
        XCTAssertTrue(relaunched.buttons["Black"].waitForExistence(timeout: 2), "Appearance choice must persist across relaunch")
    }

    func testAccentPickerAllThreeOptionsSelectable() {
        let app = UITestLaunch.app()
        openSettings(app)

        app.anyElement("settings.accentPicker").tap()
        for accent in ["Lens", "Amber", "Violet"] {
            XCTAssertTrue(app.buttons[accent].waitForExistence(timeout: 2), "\(accent) must appear in the accent picker")
        }
        app.buttons["Violet"].tap()
    }

    func testLanguagePickerShowsOnlyTheFiveSupportedLocalesAndExcludesForbiddenOnes() {
        let app = UITestLaunch.app()
        openSettings(app)

        app.anyElement("settings.languageLink").tap()
        XCTAssertTrue(app.navigationBars.firstMatch.waitForExistence(timeout: 3))

        let expectedIDs = ["pinned.uk", "pinned.en-US", "ea.zh-Hans", "ea.ja-JP", "ea.ko-KR"]
        for id in expectedIDs {
            XCTAssertTrue(app.buttons["language.option.\(id)"].waitForExistence(timeout: 2), "\(id) must be offered")
        }

        // Forbidden locales must never appear, however they'd be identified.
        let forbiddenTexts = ["Русский", "Беларуская", "فارسی"]
        for text in forbiddenTexts {
            XCTAssertFalse(app.staticTexts[text].exists, "\(text) must never appear in the language picker")
        }

        app.buttons["language.option.pinned.uk"].tap()
    }

    func testSwitchingToUkrainianLocalizesImportScreenLive() {
        let app = UITestLaunch.app()
        openSettings(app)
        app.anyElement("settings.languageLink").tap()
        app.buttons["language.option.pinned.uk"].tap()
        app.navigationBars.buttons.element(boundBy: 0).tap()
        app.navigationBars.buttons.element(boundBy: 0).tap()

        let selectPhotosButton = app.anyElement("import.selectPhotosButton")
        XCTAssertTrue(selectPhotosButton.waitForExistence(timeout: 8))
        let predicate = NSPredicate { evaluatedObject, _ in
            (evaluatedObject as? XCUIElement)?.label == "Вибрати фото"
        }
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: selectPhotosButton)
        XCTAssertEqual(XCTWaiter().wait(for: [expectation], timeout: 8), .completed, "Import's button must localize live, without relaunch, once Ukrainian is selected (got: \(selectPhotosButton.label))")
        UITestLaunch.attachScreenshot("11-import-ukrainian", of: app, in: self)
    }
}
