import Foundation

public enum WarningKind: String, Sendable, Equatable, Codable {
    case weakResolution
    case unusableResolution
    case blurry
    case underexposed
    case overexposed
    case lowContrast
    case poorFraming
    case probableDuplicate
    case verySimilar
    case missingFramingSignal
    case missingAestheticsSignal
}

public struct PhotoScore: Sendable, Equatable, Identifiable {
    public let id: PhotoID
    public let overall: Int // 0...100
    public let strengths: [String]
    public let warnings: [WarningKind]
    public let normalized: NormalizedSignals
    public let raw: RawSignals

    public init(id: PhotoID, overall: Int, strengths: [String], warnings: [WarningKind], normalized: NormalizedSignals, raw: RawSignals) {
        self.id = id
        self.overall = overall
        self.strengths = strengths
        self.warnings = warnings
        self.normalized = normalized
        self.raw = raw
    }
}

/// Deterministic 0-100 overall scoring. All weights/penalties come from `AnalysisConfig`
/// so there is exactly one place to audit or tune the model. Missing signals have their
/// weight redistributed proportionally across the remaining available signals rather
/// than silently defaulting to zero or the max — this avoids penalizing or rewarding a
/// photo for a signal we simply could not measure.
public struct ScoringEngine: Sendable {
    public init() {}

    public func score(
        id: PhotoID,
        raw: RawSignals,
        normalized: NormalizedSignals,
        redundancy: SimilarityClass?,
        isBestInCluster: Bool
    ) -> PhotoScore {
        var weighted: [(Double, Double)] = [] // (weight, value)
        if let v = normalized.resolution { weighted.append((AnalysisConfig.Weights.resolution, v)) }
        if let v = normalized.sharpness { weighted.append((AnalysisConfig.Weights.sharpness, v)) }
        if let v = normalized.exposure { weighted.append((AnalysisConfig.Weights.exposure, v)) }
        if let v = normalized.contrast { weighted.append((AnalysisConfig.Weights.contrast, v)) }
        if let v = normalized.framing { weighted.append((AnalysisConfig.Weights.framing, v)) }
        if let v = normalized.aesthetics { weighted.append((AnalysisConfig.Weights.aesthetics, v)) }

        let totalWeight = weighted.reduce(0.0) { $0 + $1.0 }
        var base: Double
        if totalWeight > 0 {
            let weightedSum = weighted.reduce(0.0) { $0 + $1.0 * $1.1 }
            base = (weightedSum / totalWeight) * 100.0
        } else {
            base = 50.0 // No signals at all: neutral, clearly not a fabricated confident score.
        }

        var penalty: Double = 0
        if raw.pixelSize.minEdge <= AnalysisConfig.Resolution.unusableMinEdgePixels {
            penalty += AnalysisConfig.Penalties.unusableResolution
        }
        if let redundancy, !isBestInCluster {
            switch redundancy {
            case .probableDuplicate: penalty += AnalysisConfig.Penalties.duplicateRedundancy
            case .verySimilar: penalty += AnalysisConfig.Penalties.verySimilarRedundancy
            case .sufficientlyDistinct: break
            }
        }

        let final = min(100.0, max(0.0, base - penalty))
        let overall = Int(final.rounded())

        var strengths: [String] = []
        var warnings: [WarningKind] = []

        if raw.pixelSize.minEdge <= AnalysisConfig.Resolution.unusableMinEdgePixels {
            warnings.append(.unusableResolution)
        } else if raw.pixelSize.minEdge < AnalysisConfig.Resolution.weakMinEdgePixels {
            warnings.append(.weakResolution)
        } else {
            strengths.append(LocalizedStringsCatalog.strengthHighResolution)
        }

        if let s = raw.sharpnessEdgeEnergy {
            if s < AnalysisConfig.Sharpness.blurryThreshold {
                warnings.append(.blurry)
            } else if s >= AnalysisConfig.Sharpness.sharpThreshold {
                strengths.append(LocalizedStringsCatalog.strengthSharp)
            }
        }

        if let luma = raw.meanLuma {
            if luma < AnalysisConfig.Exposure.underexposedMeanLuma {
                warnings.append(.underexposed)
            } else if luma > AnalysisConfig.Exposure.overexposedMeanLuma {
                warnings.append(.overexposed)
            } else {
                strengths.append(LocalizedStringsCatalog.strengthWellExposed)
            }
        }

        if let sd = raw.lumaStdDev, sd < AnalysisConfig.Contrast.lowContrastStdDev {
            warnings.append(.lowContrast)
        }

        if raw.subjectAreaFraction == nil {
            warnings.append(.missingFramingSignal)
        } else if let framingScore = normalized.framing, framingScore < 0.5 {
            warnings.append(.poorFraming)
        } else if normalized.framing != nil {
            strengths.append(LocalizedStringsCatalog.strengthWellFramed)
        }

        if raw.aestheticsScore == nil {
            warnings.append(.missingAestheticsSignal)
        }

        if let redundancy, !isBestInCluster {
            warnings.append(redundancy == .probableDuplicate ? .probableDuplicate : .verySimilar)
        }

        return PhotoScore(id: id, overall: overall, strengths: strengths, warnings: warnings, normalized: normalized, raw: raw)
    }
}

/// Placeholder hook to the localization layer for the small set of user-facing phrases
/// generated directly by the scoring engine. Full explanation text is generated in
/// `Explanations` and always resolved through `LocalizationService`.
enum LocalizedStringsCatalog {
    static let strengthHighResolution = "strength.resolution.high"
    static let strengthSharp = "strength.sharpness.high"
    static let strengthWellExposed = "strength.exposure.good"
    static let strengthWellFramed = "strength.framing.good"
}
