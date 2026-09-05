import Foundation

/// Deterministic, diversity-aware reranking that produces the "Recommended Order" for
/// listing photos: hero first, then strong-and-distinct secondaries, diverse high
/// quality photos, weaker photos later — while discouraging two near-duplicates from
/// landing next to each other near the top of the order.
///
/// Determinism guarantee: identical input scores + identical similarity pairs + identical
/// `AnalysisConfig` ⇒ identical output order, every time. This is achieved by (1) using
/// only deterministic inputs, (2) a stable sort with an explicit PhotoID tiebreaker, and
/// (3) a greedy placement algorithm that iterates candidates in a fixed, sorted order.
public struct RecommendedOrderEngine: Sendable {
    public init() {}

    public func recommend(
        scores: [PhotoScore],
        heroID: PhotoID?,
        similarityPairs: [SimilarityPair]
    ) -> [PhotoID] {
        guard !scores.isEmpty else { return [] }

        var distance: [PhotoID: [PhotoID: Float]] = [:]
        for pair in similarityPairs {
            distance[pair.a, default: [:]][pair.b] = pair.distance
            distance[pair.b, default: [:]][pair.a] = pair.distance
        }

        // Base ordering: overall score desc, then PhotoID asc for full determinism.
        let byScore = scores.sorted { a, b in
            if a.overall != b.overall { return a.overall > b.overall }
            return a.id.value.uuidString < b.id.value.uuidString
        }

        var remaining = byScore
        var ordered: [PhotoID] = []

        // Hero always leads if present.
        if let heroID, let heroIndex = remaining.firstIndex(where: { $0.id == heroID }) {
            ordered.append(remaining.remove(at: heroIndex).id)
        }

        while !remaining.isEmpty {
            var bestIndex = 0
            var bestPenalizedScore = -Double.infinity
            for (index, candidate) in remaining.enumerated() {
                var effective = Double(candidate.overall)
                if let last = ordered.last, let d = distance[last]?[candidate.id],
                   d < AnalysisConfig.Ranking.nearDuplicateAdjacencyDistance {
                    effective -= AnalysisConfig.Ranking.consecutiveNearDuplicatePenalty
                }
                // Deterministic tiebreak: prefer higher effective score, then lower index
                // (which is already score-sorted, then PhotoID-sorted).
                if effective > bestPenalizedScore {
                    bestPenalizedScore = effective
                    bestIndex = index
                }
            }
            ordered.append(remaining.remove(at: bestIndex).id)
        }

        return ordered
    }
}
