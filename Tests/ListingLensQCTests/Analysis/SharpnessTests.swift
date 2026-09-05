import XCTest
@testable import ListingLensQCCore

final class SharpnessTests: XCTestCase {
    func testSharpImageScoresHigherThanBlurredVersion() {
        let sharp = SyntheticImageFactory.sharpCheckerboard()
        let blurred = SyntheticImageFactory.blurredCheckerboard()
        let extractor = SharpnessExtractor()

        let sharpLuma = LumaBuffer.from(cgImage: sharp)!
        let blurredLuma = LumaBuffer.from(cgImage: blurred)!

        let sharpScore = extractor.edgeEnergy(of: sharpLuma)!
        let blurredScore = extractor.edgeEnergy(of: blurredLuma)!

        XCTAssertGreaterThan(sharpScore, blurredScore)
        XCTAssertGreaterThanOrEqual(sharpScore, AnalysisConfig.Sharpness.sharpThreshold)
        XCTAssertLessThan(blurredScore, AnalysisConfig.Sharpness.blurryThreshold)
    }

    func testTinyBufferReturnsNil() {
        let tiny = LumaBuffer(width: 1, height: 1, pixels: [128])
        XCTAssertNil(SharpnessExtractor().edgeEnergy(of: tiny))
    }

    func testFlatImageHasNearZeroEdgeEnergy() {
        let flat = LumaBuffer(width: 10, height: 10, pixels: [UInt8](repeating: 128, count: 100))
        let score = SharpnessExtractor().edgeEnergy(of: flat)!
        XCTAssertEqual(score, 0, accuracy: 0.0001)
    }
}
