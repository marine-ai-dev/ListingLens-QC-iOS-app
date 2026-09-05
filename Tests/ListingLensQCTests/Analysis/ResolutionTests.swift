import XCTest
@testable import ListingLensQCCore

final class ResolutionTests: XCTestCase {
    let normalizer = SignalNormalizer()

    func testTinyResolutionIsUnusable() {
        let size = PixelSize(width: 100, height: 80)
        XCTAssertLessThanOrEqual(size.minEdge, AnalysisConfig.Resolution.unusableMinEdgePixels)
        XCTAssertEqual(normalizer.normalizeResolution(size), 0.0)
    }

    func testHighResolutionScoresNearOne() {
        let size = PixelSize(width: 4000, height: 3000)
        let score = normalizer.normalizeResolution(size)
        XCTAssertGreaterThan(score, 0.9)
    }

    func testWeakResolutionFlagBoundary() {
        let justBelow = PixelSize(width: 900, height: 900)
        let justAbove = PixelSize(width: 1200, height: 1200)
        XCTAssertLessThan(justBelow.minEdge, AnalysisConfig.Resolution.weakMinEdgePixels)
        XCTAssertGreaterThanOrEqual(justAbove.minEdge, AnalysisConfig.Resolution.weakMinEdgePixels)
    }

    func testPixelCountAndMegapixels() {
        let size = PixelSize(width: 1000, height: 1000)
        XCTAssertEqual(size.pixelCount, 1_000_000)
        XCTAssertEqual(size.megapixels, 1.0, accuracy: 0.0001)
    }
}
