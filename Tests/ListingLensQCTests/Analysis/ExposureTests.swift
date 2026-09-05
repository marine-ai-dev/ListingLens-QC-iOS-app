import XCTest
@testable import ListingLensQCCore

final class ExposureTests: XCTestCase {
    private let extractor = ExposureExtractor()

    func testDarkImageIsClassifiedUnderexposed() {
        let dark = SyntheticImageFactory.darkImage()
        let luma = LumaBuffer.from(cgImage: dark)!
        let result = extractor.analyze(luma)!
        XCTAssertLessThan(result.meanLuma, AnalysisConfig.Exposure.underexposedMeanLuma)
    }

    func testOverexposedImageIsClassifiedOverexposed() {
        let bright = SyntheticImageFactory.overexposedImage()
        let luma = LumaBuffer.from(cgImage: bright)!
        let result = extractor.analyze(luma)!
        XCTAssertGreaterThan(result.meanLuma, AnalysisConfig.Exposure.overexposedMeanLuma)
        XCTAssertGreaterThan(result.blownHighlightFraction, 0.9)
    }

    func testEmptyBufferReturnsNil() {
        let empty = LumaBuffer(width: 0, height: 0, pixels: [])
        XCTAssertNil(extractor.analyze(empty))
    }

    func testCheckerboardHasHighContrast() {
        let sharp = SyntheticImageFactory.sharpCheckerboard()
        let luma = LumaBuffer.from(cgImage: sharp)!
        let result = extractor.analyze(luma)!
        XCTAssertGreaterThan(result.stdDev, AnalysisConfig.Contrast.lowContrastStdDev)
    }
}
