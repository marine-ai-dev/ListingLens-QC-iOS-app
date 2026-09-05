import Foundation
import CoreGraphics

/// Per-photo outcome: either a full set of signals, or a recorded failure that does not
/// invalidate the rest of the batch.
public enum PhotoAnalysisOutcome: Sendable {
    case success(PhotoScore)
    case failure(PhotoID, AnalysisError)
}

public struct AnalysisReport: Sendable {
    public let scores: [PhotoScore]
    public let failures: [(PhotoID, AnalysisError)]
    public let similarityPairs: [SimilarityPair]
    public let clusters: [[PhotoID]]
    public let hero: HeroCandidate?
    public let recommendedOrder: [PhotoID]
}

/// Orchestrates PhotoInput -> Decoding -> SignalExtraction -> Normalization -> Similarity
/// -> Scoring -> HeroScoring -> Ranking. Uses a bounded TaskGroup so at most
/// `AnalysisConfig.maxConcurrentAnalysisTasks` photos are decoded/analyzed at once,
/// keeping peak memory bounded for batches of up to 20 full-resolution source photos.
/// All heavy work happens off the main actor.
public actor AnalysisPipeline {
    private let decoder = ImageDecoder()
    private let sharpness = SharpnessExtractor()
    private let exposure = ExposureExtractor()
    private let framing = FramingExtractor()
    private let aesthetics = AestheticsExtractor()
    private let normalizer = SignalNormalizer()
    private let similarityEngine = SimilarityEngine()
    private let scoringEngine = ScoringEngine()
    private let heroEngine = HeroScoringEngine()
    private let rankingEngine = RecommendedOrderEngine()

    public init() {}

    public func run(_ inputs: [PhotoInput]) async -> AnalysisReport {
        guard !inputs.isEmpty else {
            return AnalysisReport(scores: [], failures: [], similarityPairs: [], clusters: [], hero: nil, recommendedOrder: [])
        }
        let clamped = Array(inputs.prefix(AnalysisConfig.maxBatchSize))

        var decoded: [PhotoID: DecodedImage] = [:]
        var rawSignalsByID: [PhotoID: RawSignals] = [:]
        var failures: [(PhotoID, AnalysisError)] = []
        var featurePrints: [PhotoID: VNFeaturePrintObservationBox] = [:]

        await withTaskGroup(of: (PhotoID, Result<(DecodedImage, RawSignals, VNFeaturePrintObservationBox?), AnalysisError>).self) { group in
            var iterator = clamped.makeIterator()
            var active = 0
            let limit = AnalysisConfig.maxConcurrentAnalysisTasks

            func enqueueNext() {
                guard let input = iterator.next() else { return }
                active += 1
                group.addTask { [decoder, sharpness, exposure, framing, aesthetics, similarityEngine] in
                    if Task.isCancelled { return (input.id, .failure(.cancelled)) }
                    do {
                        let image = try decoder.decode(input)
                        guard let luma = LumaBuffer.from(cgImage: image.analysisImage) else {
                            return (input.id, .failure(.decodeFailed))
                        }
                        let edgeEnergy = sharpness.edgeEnergy(of: luma)
                        let exposureResult = exposure.analyze(luma)
                        let framingResult = framing.analyze(image.analysisImage)
                        let aestheticsScore = aesthetics.score(image.analysisImage)
                        let raw = RawSignals(
                            pixelSize: image.originalSize,
                            sharpnessEdgeEnergy: edgeEnergy,
                            meanLuma: exposureResult?.meanLuma,
                            lumaStdDev: exposureResult?.stdDev,
                            crushedShadowFraction: exposureResult?.crushedShadowFraction,
                            blownHighlightFraction: exposureResult?.blownHighlightFraction,
                            subjectAreaFraction: framingResult?.subjectAreaFraction,
                            subjectCenterOffset: framingResult?.centerOffset,
                            aestheticsScore: aestheticsScore,
                            visionAvailable: framingResult != nil || aestheticsScore != nil
                        )
                        let fp = similarityEngine.featurePrint(for: image.analysisImage)
                        return (input.id, .success((image, raw, fp)))
                    } catch let error as AnalysisError {
                        return (input.id, .failure(error))
                    } catch {
                        return (input.id, .failure(.decodeFailed))
                    }
                }
            }

            for _ in 0..<limit { enqueueNext() }

            while let (id, result) = await group.next() {
                active -= 1
                switch result {
                case .success((let image, let raw, let fp)):
                    decoded[id] = image
                    rawSignalsByID[id] = raw
                    if let fp { featurePrints[id] = fp }
                case .failure(let error):
                    failures.append((id, error))
                }
                if active < limit { enqueueNext() }
            }
        }

        // Similarity
        let pairs = similarityEngine.pairwiseSimilarities(featurePrints)
        let allIDs = Array(rawSignalsByID.keys)
        let clusters = similarityEngine.clusters(from: pairs, allIDs: allIDs)

        // Determine, per cluster, which member is "best" (highest raw sharpness+resolution
        // proxy) so only non-best members are penalized for redundancy.
        var bestInClusterByID: [PhotoID: Bool] = [:]
        for id in allIDs { bestInClusterByID[id] = true }
        for cluster in clusters {
            let ranked = cluster.sorted { a, b in
                let sa = rawSignalsByID[a]?.sharpnessEdgeEnergy ?? 0
                let sb = rawSignalsByID[b]?.sharpnessEdgeEnergy ?? 0
                if sa != sb { return sa > sb }
                return a.value.uuidString < b.value.uuidString
            }
            for (index, id) in ranked.enumerated() {
                bestInClusterByID[id] = (index == 0)
            }
        }

        func redundancyClass(for id: PhotoID) -> SimilarityClass? {
            pairs.filter { $0.a == id || $0.b == id }
                .filter { $0.classification != .sufficientlyDistinct }
                .min(by: { $0.distance < $1.distance })?
                .classification
        }

        var scores: [PhotoScore] = []
        for id in allIDs {
            guard let raw = rawSignalsByID[id] else { continue }
            let normalized = normalizer.normalize(raw)
            let redundancy = redundancyClass(for: id)
            let isBest = bestInClusterByID[id] ?? true
            scores.append(scoringEngine.score(id: id, raw: raw, normalized: normalized, redundancy: redundancy, isBestInCluster: isBest))
        }

        var redundancyPenalties: [PhotoID: Double] = [:]
        for id in allIDs {
            switch redundancyClass(for: id) {
            case .probableDuplicate: redundancyPenalties[id] = (bestInClusterByID[id] == true) ? 0 : 1.0
            case .verySimilar: redundancyPenalties[id] = (bestInClusterByID[id] == true) ? 0 : 0.5
            default: redundancyPenalties[id] = 0
            }
        }

        let hero = heroEngine.selectHero(scores: scores, redundancyPenalties: redundancyPenalties)
        let order = rankingEngine.recommend(scores: scores, heroID: hero?.id, similarityPairs: pairs)

        return AnalysisReport(
            scores: scores,
            failures: failures,
            similarityPairs: pairs,
            clusters: clusters,
            hero: hero,
            recommendedOrder: order
        )
    }
}
