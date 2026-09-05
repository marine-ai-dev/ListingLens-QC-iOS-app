import XCTest
@testable import ListingLensQCCore

final class HeroAndRankingTests: XCTestCase {
    private func score(_ overall: Int, sharpness: Double, resolution: Double, framing: Double? = 0.8, id: PhotoID = PhotoID()) -> PhotoScore {
        let raw = RawSignals(pixelSize: PixelSize(width: 3000, height: 2000), sharpnessEdgeEnergy: 40, meanLuma: 130, lumaStdDev: 50)
        let normalized = NormalizedSignals(resolution: resolution, sharpness: sharpness, exposure: 0.8, contrast: 0.8, framing: framing, aesthetics: 0.7, saliencyAvailable: framing != nil)
        return PhotoScore(id: id, overall: overall, strengths: [], warnings: [], normalized: normalized, raw: raw)
    }

    func testHeroSelectionAlwaysReturnsExactlyOneForNonEmptyBatch() {
        let scores = [score(70, sharpness: 0.5, resolution: 0.5), score(90, sharpness: 0.9, resolution: 0.9)]
        let hero = HeroScoringEngine().selectHero(scores: scores, redundancyPenalties: [:])
        XCTAssertNotNil(hero)
    }

    func testHeroPrefersHigherQualityOverJustMaxOverall() {
        // Photo A has slightly higher overall but is a duplicate (penalized);
        // Photo B is fully distinct and nearly as good -> hero should favor B.
        let a = score(85, sharpness: 0.6, resolution: 0.6, id: PhotoID())
        let b = score(82, sharpness: 0.9, resolution: 0.9, id: PhotoID())
        let penalties: [PhotoID: Double] = [a.id: 1.0, b.id: 0.0]
        let hero = HeroScoringEngine().selectHero(scores: [a, b], redundancyPenalties: penalties)
        XCTAssertEqual(hero?.id, b.id)
    }

    func testHeroSelectionIsDeterministicForTiedScores() {
        let id1 = PhotoID(UUID(uuidString: "00000000-0000-0000-0000-000000000001")!)
        let id2 = PhotoID(UUID(uuidString: "00000000-0000-0000-0000-000000000002")!)
        let a = score(80, sharpness: 0.7, resolution: 0.7, id: id1)
        let b = score(80, sharpness: 0.7, resolution: 0.7, id: id2)
        let hero1 = HeroScoringEngine().selectHero(scores: [a, b], redundancyPenalties: [:])
        let hero2 = HeroScoringEngine().selectHero(scores: [b, a], redundancyPenalties: [:])
        XCTAssertEqual(hero1?.id, hero2?.id)
        XCTAssertEqual(hero1?.id, id1) // lexicographically smaller UUID wins ties
    }

    func testSingleImageBatchAlwaysHasHero() {
        let a = score(50, sharpness: 0.3, resolution: 0.3)
        let hero = HeroScoringEngine().selectHero(scores: [a], redundancyPenalties: [:])
        XCTAssertEqual(hero?.id, a.id)
    }

    func testRecommendedOrderIsDeterministicAcrossRuns() {
        let scores = (0..<6).map { i in score(60 + i * 5, sharpness: 0.5, resolution: 0.5) }
        let engine = RecommendedOrderEngine()
        let order1 = engine.recommend(scores: scores, heroID: scores.last?.id, similarityPairs: [])
        let order2 = engine.recommend(scores: scores, heroID: scores.last?.id, similarityPairs: [])
        XCTAssertEqual(order1, order2)
    }

    func testRecommendedOrderPutsHeroFirst() {
        let scores = (0..<5).map { i in score(60 + i * 5, sharpness: 0.5, resolution: 0.5) }
        let hero = scores[2] // not the max-overall one
        let order = RecommendedOrderEngine().recommend(scores: scores, heroID: hero.id, similarityPairs: [])
        XCTAssertEqual(order.first, hero.id)
    }

    func testRecommendedOrderPenalizesConsecutiveNearDuplicates() {
        let a = score(90, sharpness: 0.9, resolution: 0.9)
        let dup = score(89, sharpness: 0.88, resolution: 0.88) // near-duplicate of `a`
        let distinct = score(80, sharpness: 0.7, resolution: 0.7) // distinct, lower score

        let pairs = [SimilarityPair(a: a.id, b: dup.id, distance: 0.1, classification: .probableDuplicate)]
        let order = RecommendedOrderEngine().recommend(scores: [a, dup, distinct], heroID: a.id, similarityPairs: pairs)

        // The near-duplicate of the hero should be pushed behind the distinct photo,
        // even though its raw overall score is higher.
        XCTAssertEqual(order, [a.id, distinct.id, dup.id])
    }

    func testRecommendedOrderHandlesEmptyBatch() {
        let order = RecommendedOrderEngine().recommend(scores: [], heroID: nil, similarityPairs: [])
        XCTAssertTrue(order.isEmpty)
    }
}
