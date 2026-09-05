import XCTest
@testable import ListingLensQCCore

final class SimilarityTests: XCTestCase {
    func testClassificationThresholds() {
        XCTAssertEqual(SimilarityEngine.classify(distance: 0.05), .probableDuplicate)
        XCTAssertEqual(SimilarityEngine.classify(distance: 0.14999), .probableDuplicate)
        XCTAssertEqual(SimilarityEngine.classify(distance: 0.15), .verySimilar)
        XCTAssertEqual(SimilarityEngine.classify(distance: 0.25), .verySimilar)
        XCTAssertEqual(SimilarityEngine.classify(distance: 0.30), .sufficientlyDistinct)
        XCTAssertEqual(SimilarityEngine.classify(distance: 0.9), .sufficientlyDistinct)
    }

    func testClusteringGroupsOnlyNonDistinctPairs() {
        let a = PhotoID(), b = PhotoID(), c = PhotoID()
        let pairs = [
            SimilarityPair(a: a, b: b, distance: 0.1, classification: .probableDuplicate),
            SimilarityPair(a: b, b: c, distance: 0.9, classification: .sufficientlyDistinct)
        ]
        let clusters = SimilarityEngine().clusters(from: pairs, allIDs: [a, b, c])
        XCTAssertEqual(clusters.count, 1)
        XCTAssertEqual(Set(clusters[0]), Set([a, b]))
    }

    func testNoClustersWhenAllDistinct() {
        let a = PhotoID(), b = PhotoID()
        let pairs = [SimilarityPair(a: a, b: b, distance: 0.9, classification: .sufficientlyDistinct)]
        let clusters = SimilarityEngine().clusters(from: pairs, allIDs: [a, b])
        XCTAssertTrue(clusters.isEmpty)
    }

    func testTransitiveClustering() {
        // a~b (duplicate), b~c (very similar) => {a,b,c} one cluster even though a-c
        // was never directly compared as similar.
        let a = PhotoID(), b = PhotoID(), c = PhotoID()
        let pairs = [
            SimilarityPair(a: a, b: b, distance: 0.1, classification: .probableDuplicate),
            SimilarityPair(a: b, b: c, distance: 0.2, classification: .verySimilar)
        ]
        let clusters = SimilarityEngine().clusters(from: pairs, allIDs: [a, b, c])
        XCTAssertEqual(clusters.count, 1)
        XCTAssertEqual(clusters[0].count, 3)
    }
}
