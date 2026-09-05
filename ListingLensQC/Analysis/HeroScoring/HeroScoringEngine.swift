import Foundation

public struct HeroCandidate: Sendable, Equatable {
    public let id: PhotoID
    public let heroScore: Double
    public let reasons: [String] // localization keys
}

/// Best Hero Candidate selection: a distinct ranking from the overall QC score.
/// Rewards quality, resolution, sharpness, framing, saliency, aesthetics, and
/// *penalizes* redundancy so a duplicate of an otherwise-great shot doesn't win by
/// coincidence. Always produces exactly one winner for any non-empty batch — ties are
/// broken deterministically by PhotoID so re-running the same batch is stable.
public struct HeroScoringEngine: Sendable {
    public init() {}

    public func rank(scores: [PhotoScore], redundancyPenalties: [PhotoID: Double]) -> [HeroCandidate] {
        let candidates: [HeroCandidate] = scores.map { score in
            let w = AnalysisConfig.HeroWeights.self
            var value: Double = 0
            value += w.overallScore * (Double(score.overall) / 100.0)
            value += w.sharpness * (score.normalized.sharpness ?? 0.5)
            value += w.resolution * (score.normalized.resolution ?? 0.5)
            value += w.framing * (score.normalized.framing ?? 0.5)
            value += w.saliency * (score.normalized.saliencyAvailable ? 1.0 : 0.5)
            value += w.aesthetics * (score.normalized.aesthetics ?? 0.5)
            let redundancy = redundancyPenalties[score.id] ?? 0
            value -= w.redundancyPenalty * redundancy

            var reasons: [String] = []
            if score.overall >= 80 { reasons.append("hero.reason.highOverall") }
            if (score.normalized.sharpness ?? 0) >= 0.7 { reasons.append("hero.reason.sharp") }
            if (score.normalized.resolution ?? 0) >= 0.8 { reasons.append("hero.reason.resolution") }
            if (score.normalized.framing ?? 0) >= 0.7 { reasons.append("hero.reason.framing") }
            if redundancy == 0 { reasons.append("hero.reason.distinct") }
            if reasons.isEmpty { reasons.append("hero.reason.bestAvailable") }

            return HeroCandidate(id: score.id, heroScore: value, reasons: reasons)
        }

        // Stable deterministic sort: heroScore desc, then PhotoID string asc as tiebreaker.
        return candidates.sorted { a, b in
            if a.heroScore != b.heroScore { return a.heroScore > b.heroScore }
            return a.id.value.uuidString < b.id.value.uuidString
        }
    }

    /// Always returns exactly one hero for a non-empty input.
    public func selectHero(scores: [PhotoScore], redundancyPenalties: [PhotoID: Double]) -> HeroCandidate? {
        rank(scores: scores, redundancyPenalties: redundancyPenalties).first
    }
}
