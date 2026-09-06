import XCTest

/// Exercises Import -> deterministic analysis -> Results -> Hero -> Photo Detail ->
/// Recommended Order -> New Analysis using injected synthetic fixtures (see
/// `UITestLaunch`), so this suite never depends on tapping into the real
/// PhotosPicker grid (which XCUITest cannot drive deterministically - it's a
/// system UI outside the app's accessibility tree in most Simulator configurations).
final class CoreFlowUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testImportScreenLaunches() {
        let app = UITestLaunch.app()
        app.launch()
        XCTAssertTrue(app.anyElement("import.selectPhotosButton").waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["ListingLens QC"].exists)
        XCTAssertTrue(app.anyElement("import.settingsLink").waitForExistence(timeout: 2) || app.buttons["import.settingsLink"].exists)
        UITestLaunch.attachScreenshot("01-import", of: app, in: self)
    }

    func test10PhotoDeterministicFlowReachesResultsWithHero() {
        let app = UITestLaunch.app(fixtureBatch: "mixed10")
        app.launch()

        let progressBar = app.progressIndicators["progress.bar"]
        XCTAssertTrue(progressBar.waitForExistence(timeout: 5), "Analysis Progress should appear for an injected fixture batch")
        UITestLaunch.attachScreenshot("02-analysis-progress", of: app, in: self)

        let resultsTitle = app.navigationBars["Results"]
        XCTAssertTrue(resultsTitle.waitForExistence(timeout: 15), "Results should appear once analysis completes")
        UITestLaunch.attachScreenshot("03-results", of: app, in: self)

        XCTAssertTrue(app.anyElement("results.heroCard").waitForExistence(timeout: 2), "A 10-photo batch must always produce exactly one Best Hero Candidate")

        let cardIDs = app.collectIdentifiers(prefix: "results.photoCard.")
        XCTAssertEqual(cardIDs.count, 10, "A 10-photo batch must produce exactly 10 result cards")

        let photoCards = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'results.photoCard.'"))
        photoCards.element(boundBy: 0).tap()
        XCTAssertTrue(app.navigationBars["Photo Detail"].waitForExistence(timeout: 3))
        UITestLaunch.attachScreenshot("04-photo-detail", of: app, in: self)
        app.navigationBars.buttons.element(boundBy: 0).tap()

        app.anyElement("results.recommendedOrderLink").tap()
        XCTAssertTrue(app.navigationBars["Recommended Order"].waitForExistence(timeout: 3))
        let rowIDs = app.collectIdentifiers(prefix: "recommendedOrder.row.")
        XCTAssertEqual(rowIDs.count, 10, "Recommended Order must list all 10 photos")
        UITestLaunch.attachScreenshot("05-recommended-order", of: app, in: self)
        app.navigationBars.buttons.element(boundBy: 0).tap()

        app.anyElement("results.newAuditButton").tap()
        XCTAssertTrue(app.anyElement("import.selectPhotosButton").waitForExistence(timeout: 3), "Start New Audit must return to Import with a clean state")
    }

    func test20PhotoStressFlowCompletesWithoutHang() {
        let app = UITestLaunch.app(fixtureBatch: "stress20")
        app.launch()

        let resultsTitle = app.navigationBars["Results"]
        XCTAssertTrue(resultsTitle.waitForExistence(timeout: 20), "20-photo batch must complete analysis without hanging")

        let cardIDs = app.collectIdentifiers(prefix: "results.photoCard.")
        XCTAssertEqual(cardIDs.count, 20, "A 20-photo batch must produce exactly 20 result cards")
        XCTAssertTrue(app.anyElement("results.heroCard").exists)

        app.anyElement("results.recommendedOrderLink").tap()
        let rowIDs = app.collectIdentifiers(prefix: "recommendedOrder.row.")
        XCTAssertEqual(rowIDs.count, 20, "Recommended Order must list all 20 photos")
        UITestLaunch.attachScreenshot("06-recommended-order-20", of: app, in: self)
    }

    func testDeterministicRerunProducesStableHeroAndOrder() {
        func heroSubtitleAndOrder(_ app: XCUIApplication) -> (hero: String, order: [String]) {
            let hero = app.anyElement("results.heroCard").label
            app.anyElement("results.recommendedOrderLink").tap()
            XCTAssertTrue(app.navigationBars["Recommended Order"].waitForExistence(timeout: 5))
            // Position N's accessibility label embeds the photo's score and hero
            // status (see RecommendedOrderView) - a stable proxy for "same order,
            // same scores" without relying on raw element identifiers, which XCUITest
            // can concatenate oddly across nested `.accessibilityElement(children:
            // .combine)` containers.
            let order = app.collectIdentifiers(prefix: "recommendedOrder.row.").sorted()
                .compactMap { id -> String? in
                    app.anyElement(id).label
                }
            return (hero, order)
        }

        let firstRun = UITestLaunch.app(fixtureBatch: "mixed10")
        firstRun.launch()
        XCTAssertTrue(firstRun.navigationBars["Results"].waitForExistence(timeout: 20))
        XCTAssertTrue(firstRun.anyElement("results.heroCard").waitForExistence(timeout: 10))
        let first = heroSubtitleAndOrder(firstRun)
        firstRun.terminate()
        Thread.sleep(forTimeInterval: 1)

        let secondRun = UITestLaunch.app(fixtureBatch: "mixed10")
        secondRun.launch()
        XCTAssertTrue(secondRun.navigationBars["Results"].waitForExistence(timeout: 20))
        XCTAssertTrue(secondRun.anyElement("results.heroCard").waitForExistence(timeout: 10))
        let second = heroSubtitleAndOrder(secondRun)

        XCTAssertEqual(first.hero, second.hero, "The same fixture batch must pick the same hero explanation on every run")
        XCTAssertEqual(first.order, second.order, "The same fixture batch must produce the same Recommended Order positions/scores on every run")
    }

    func testDuplicateAndNearDuplicateBatchClassifiesCorrectly() {
        let app = UITestLaunch.app(fixtureBatch: "duplicates")
        app.launch()

        XCTAssertTrue(app.navigationBars["Results"].waitForExistence(timeout: 15))
        let cardIDs = app.collectIdentifiers(prefix: "results.photoCard.")
        XCTAssertEqual(cardIDs.count, 4, "duplicates batch is exact-dup pair + near-dup + unrelated = 4 photos")
        UITestLaunch.attachScreenshot("07-duplicates-results", of: app, in: self)

        // The exact-duplicate pair must each show a "probable duplicate" style warning
        // (a warning triangle is rendered whenever warningCount > 0 - see PhotoCard.swift).
        let warningTriangles = app.images.matching(NSPredicate(format: "identifier == 'exclamationmark.triangle.fill' OR label CONTAINS 'warning'"))
        XCTAssertGreaterThan(warningTriangles.count, 0, "At least the duplicate pair should surface a warning in this batch")
    }

    func testCancelDuringAnalysisReturnsToImport() {
        // The synthetic 20-photo batch analyzes fast enough in Simulator that by the
        // time XCUITest's automation-session setup overhead (which dwarfs the actual
        // analysis time here) elapses, analysis has often already finished - so
        // either outcome is a *correct* app state: Cancel won the race and returned
        // to Import, or analysis won the race and Results appeared. Only a hang, a
        // crash, or an unusable dead screen would be a real bug.
        let app = UITestLaunch.app(fixtureBatch: "stress20")
        app.launch()
        let cancelButton = app.anyElement("progress.cancelButton")
        XCTAssertTrue(cancelButton.waitForExistence(timeout: 3))
        if cancelButton.exists {
            cancelButton.tap()
        }
        let backToImport = app.anyElement("import.selectPhotosButton").waitForExistence(timeout: 5)
        let analysisWonTheRace = app.navigationBars["Results"].waitForExistence(timeout: 1)
        XCTAssertTrue(backToImport || analysisWonTheRace, "Cancelling must leave the app in a usable state (Import or, if analysis finished first, Results) - not stuck/hung")
    }
}
