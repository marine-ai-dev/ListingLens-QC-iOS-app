import Foundation
import CoreGraphics
#if canImport(Vision)
import Vision
#endif

public enum SimilarityClass: String, Sendable, Equatable, Codable {
    case probableDuplicate
    case verySimilar
    case sufficientlyDistinct
}

public struct SimilarityPair: Sendable, Equatable {
    public let a: PhotoID
    public let b: PhotoID
    public let distance: Float
    public let classification: SimilarityClass
}

/// Pairwise similarity/duplicate detection using Vision's on-device feature print
/// embeddings. Never deletes anything — only classifies and groups for the UI to present
/// as a warning, leaving the decision to the user.
public struct SimilarityEngine: Sendable {
    public init() {}

    /// Computes a VNFeaturePrintObservation for a decoded image, or nil if Vision is
    /// unavailable/fails (feature-print absence degrades similarity detection gracefully;
    /// it never fabricates a similarity result).
    public func featurePrint(for image: CGImage) -> VNFeaturePrintObservationBox? {
        #if canImport(Vision)
        let request = VNGenerateImageFeaturePrintRequest()
        let handler = VNImageRequestHandler(cgImage: image, options: [:])
        do {
            try handler.perform([request])
            guard let observation = request.results?.first else { return nil }
            return VNFeaturePrintObservationBox(observation: observation)
        } catch {
            return nil
        }
        #else
        return nil
        #endif
    }

    public static func classify(distance: Float) -> SimilarityClass {
        if distance < AnalysisConfig.Similarity.duplicateDistance {
            return .probableDuplicate
        } else if distance < AnalysisConfig.Similarity.verySimilarDistance {
            return .verySimilar
        } else {
            return .sufficientlyDistinct
        }
    }

    /// Computes all pairwise distances/classifications for a batch. O(n^2) but bounded
    /// to n=20 max photos, so this stays fast and simple.
    public func pairwiseSimilarities(_ prints: [PhotoID: VNFeaturePrintObservationBox]) -> [SimilarityPair] {
        let ids = Array(prints.keys)
        var results: [SimilarityPair] = []
        guard ids.count > 1 else { return results }
        for i in 0..<(ids.count - 1) {
            for j in (i + 1)..<ids.count {
                guard let a = prints[ids[i]], let b = prints[ids[j]] else { continue }
                guard let distance = a.distance(to: b) else { continue }
                results.append(SimilarityPair(a: ids[i], b: ids[j], distance: distance, classification: Self.classify(distance: distance)))
            }
        }
        return results
    }

    /// Groups photos into similarity clusters using union-find over probable-duplicate
    /// and very-similar edges, so the UI can present "these N photos look alike" groups.
    public func clusters(from pairs: [SimilarityPair], allIDs: [PhotoID]) -> [[PhotoID]] {
        var parent: [PhotoID: PhotoID] = [:]
        func find(_ x: PhotoID) -> PhotoID {
            var x = x
            while let p = parent[x], p != x { x = p }
            return x
        }
        func union(_ a: PhotoID, _ b: PhotoID) {
            let ra = find(a), rb = find(b)
            if ra != rb { parent[ra] = rb }
        }
        for id in allIDs { parent[id] = id }
        for pair in pairs where pair.classification != .sufficientlyDistinct {
            union(pair.a, pair.b)
        }
        var groups: [PhotoID: [PhotoID]] = [:]
        for id in allIDs {
            groups[find(id), default: []].append(id)
        }
        return groups.values.filter { $0.count > 1 }.sorted { ($0.first?.value.uuidString ?? "") < ($1.first?.value.uuidString ?? "") }
    }
}

/// Thin Sendable wrapper around VNFeaturePrintObservation (which is not Sendable itself)
/// so it can cross actor boundaries within our own pipeline safely.
public final class VNFeaturePrintObservationBox: @unchecked Sendable {
    #if canImport(Vision)
    private let observation: VNFeaturePrintObservation
    init(observation: VNFeaturePrintObservation) { self.observation = observation }

    func distance(to other: VNFeaturePrintObservationBox) -> Float? {
        var distance: Float = 0
        do {
            try observation.computeDistance(&distance, to: other.observation)
            return distance
        } catch {
            return nil
        }
    }
    #else
    func distance(to other: VNFeaturePrintObservationBox) -> Float? { nil }
    #endif
}
