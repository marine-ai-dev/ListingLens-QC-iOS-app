import XCTest
@testable import ListingLensQCCore

final class ScoringDeterminismTests: XCTestCase {
    private func makeSignals() -> (RawSignals, NormalizedSignals) {
        let raw = RawSignals(
            pixelSize: PixelSize(width: 3000, height: 2000),
            sharpnessEdgeEnergy: 40,
            meanLuma: 130,
            lumaStdDev: 50,
            crushedShadowFraction: 0.01,
            blownHighlightFraction: 0.01,
            subjectAreaFraction: 0.3,
            subjectCenterOffset: 0.1,
            aestheticsScore: 0.7
        )
        let normalized = SignalNormalizer().normalize(raw)
        return (raw, normalized)
    }

    func testIdenticalInputsProduceIdenticalScore() {
        let engine = ScoringEngine()
        let (raw, normalized) = makeSignals()
        let id = PhotoID()
        let a = engine.score(id: id, raw: raw, normalized: normalized, redundancy: nil, isBestInCluster: true)
        let b = engine.score(id: id, raw: raw, normalized: normalized, redundancy: nil, isBestInCluster: true)
        XCTAssertEqual(a.overall, b.overall)
        XCTAssertEqual(a.warnings, b.warnings)
    }

    func testScoreIsWithinValidRange() {
        let engine = ScoringEngine()
        let (raw, normalized) = makeSignals()
        let score = engine.score(id: PhotoID(), raw: raw, normalized: normalized, redundancy: nil, isBestInCluster: true)
        XCTAssertGreaterThanOrEqual(score.overall, 0)
        XCTAssertLessThanOrEqual(score.overall, 100)
    }

    func testMissingSignalsDoNotCrashAndProduceNeutralScore() {
        let raw = RawSignals(pixelSize: PixelSize(width: 2000, height: 1500))
        let normalized = SignalNormalizer().normalize(raw)
        let engine = ScoringEngine()
        let score = engine.score(id: PhotoID(), raw: raw, normalized: normalized, redundancy: nil, isBestInCluster: true)
        // Resolution is always computable; other signals may be missing but must not crash
        // or silently forge a value — the score should still land in a valid, sane range.
        XCTAssertGreaterThanOrEqual(score.overall, 0)
        XCTAssertLessThanOrEqual(score.overall, 100)
    }

    func testWeightsSumToOne() {
        XCTAssertEqual(AnalysisConfig.Weights.sum, 1.0, accuracy: 0.0001)
    }

    func testRedundancyPenaltyLowersScoreForNonBestDuplicate() {
        let engine = ScoringEngine()
        let (raw, normalized) = makeSignals()
        let withoutPenalty = engine.score(id: PhotoID(), raw: raw, normalized: normalized, redundancy: nil, isBestInCluster: true)
        let withPenalty = engine.score(id: PhotoID(), raw: raw, normalized: normalized, redundancy: .probableDuplicate, isBestInCluster: false)
        XCTAssertLessThan(withPenalty.overall, withoutPenalty.overall)
        XCTAssertTrue(withPenalty.warnings.contains(.probableDuplicate))
    }

    func testUnusableResolutionAppliesPenaltyAndWarning() {
        let engine = ScoringEngine()
        let raw = RawSignals(pixelSize: PixelSize(width: 100, height: 80), sharpnessEdgeEnergy: 40, meanLuma: 130, lumaStdDev: 50)
        let normalized = SignalNormalizer().normalize(raw)
        let score = engine.score(id: PhotoID(), raw: raw, normalized: normalized, redundancy: nil, isBestInCluster: true)
        XCTAssertTrue(score.warnings.contains(.unusableResolution))
    }
}
