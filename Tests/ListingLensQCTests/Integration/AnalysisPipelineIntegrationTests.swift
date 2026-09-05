import XCTest
@testable import ListingLensQCCore

final class AnalysisPipelineIntegrationTests: XCTestCase {

    private func input(from image: CGImage) -> PhotoInput {
        PhotoInput(data: SyntheticImageFactory.pngData(from: image))
    }

    func testEmptyBatchProducesEmptyReport() async {
        let report = await AnalysisPipeline().run([])
        XCTAssertTrue(report.scores.isEmpty)
        XCTAssertNil(report.hero)
        XCTAssertTrue(report.recommendedOrder.isEmpty)
    }

    func testSinglePhotoBatchAlwaysHasExactlyOneHero() async {
        let report = await AnalysisPipeline().run([input(from: SyntheticImageFactory.sharpCheckerboard())])
        XCTAssertEqual(report.scores.count, 1)
        XCTAssertNotNil(report.hero)
        XCTAssertEqual(report.recommendedOrder.count, 1)
    }

    func testCorruptDataDoesNotInvalidateRestOfBatch() async {
        let good = input(from: SyntheticImageFactory.sharpCheckerboard())
        let corrupt = PhotoInput(data: Data([0x00, 0x01, 0x02]))
        let report = await AnalysisPipeline().run([good, corrupt])
        XCTAssertEqual(report.scores.count, 1)
        XCTAssertEqual(report.failures.count, 1)
        XCTAssertNotNil(report.hero)
    }

    func testEmptyDataFailsGracefully() async {
        let report = await AnalysisPipeline().run([PhotoInput(data: Data())])
        XCTAssertTrue(report.scores.isEmpty)
        XCTAssertEqual(report.failures.count, 1)
        XCTAssertEqual(report.failures.first?.1, .emptyData)
    }

    func testTwentyPhotoBatchCompletesAndProducesOneHeroAndFullOrder() async {
        var images: [CGImage] = []
        for i in 0..<20 {
            images.append(i % 2 == 0 ? SyntheticImageFactory.sharpCheckerboard() : SyntheticImageFactory.centralSubjectImage())
        }
        let inputs = images.map(input(from:))
        let report = await AnalysisPipeline().run(inputs)
        XCTAssertEqual(report.scores.count, 20)
        XCTAssertNotNil(report.hero)
        XCTAssertEqual(Set(report.recommendedOrder), Set(report.scores.map(\.id)))
        XCTAssertEqual(report.recommendedOrder.count, 20)
    }

    func testMoreThanMaxBatchSizeIsClamped() async {
        var inputs: [PhotoInput] = []
        for _ in 0..<25 {
            inputs.append(input(from: SyntheticImageFactory.centralSubjectImage()))
        }
        let report = await AnalysisPipeline().run(inputs)
        XCTAssertLessThanOrEqual(report.scores.count + report.failures.count, AnalysisConfig.maxBatchSize)
    }

    func testExactDuplicateIsClassifiedAndFlaggedNotAutoDeleted() async {
        let img = SyntheticImageFactory.centralSubjectImage()
        let data = SyntheticImageFactory.pngData(from: img)
        let a = PhotoInput(data: data)
        let b = PhotoInput(data: data) // byte-identical => guaranteed duplicate
        let report = await AnalysisPipeline().run([a, b])
        XCTAssertEqual(report.scores.count, 2, "duplicates are flagged, never removed from the batch")
        let hasRedundancyWarning = report.scores.contains { $0.warnings.contains(.probableDuplicate) || $0.warnings.contains(.verySimilar) }
        // Feature-print may be unavailable on non-Apple CI; only assert when Vision ran.
        if !report.similarityPairs.isEmpty {
            XCTAssertTrue(hasRedundancyWarning)
        }
    }

    func testDeterminismAcrossRepeatedRunsOfSameBatch() async {
        let inputs = (0..<6).map { i in
            input(from: i % 2 == 0 ? SyntheticImageFactory.sharpCheckerboard() : SyntheticImageFactory.darkImage())
        }
        let report1 = await AnalysisPipeline().run(inputs)
        let report2 = await AnalysisPipeline().run(inputs)
        let scores1 = report1.scores.sorted { $0.id.value.uuidString < $1.id.value.uuidString }.map(\.overall)
        let scores2 = report2.scores.sorted { $0.id.value.uuidString < $1.id.value.uuidString }.map(\.overall)
        XCTAssertEqual(scores1, scores2)
    }

    func testCancellationStopsWithoutCrashing() async {
        let inputs = (0..<20).map { _ in input(from: SyntheticImageFactory.highResolution()) }
        let pipeline = AnalysisPipeline()
        let task = Task { await pipeline.run(inputs) }
        task.cancel()
        _ = await task.value // must complete (not hang) even when cancelled immediately
        XCTAssertTrue(true)
    }
}
