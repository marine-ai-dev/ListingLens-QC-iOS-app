import Foundation

/// Normalized (0...1) per-signal scores, with `nil` preserved for missing signals so
/// downstream aggregation can redistribute weight rather than fabricate a value.
public struct NormalizedSignals: Sendable, Equatable {
    public var resolution: Double?
    public var sharpness: Double?
    public var exposure: Double?
    public var contrast: Double?
    public var framing: Double?
    public var aesthetics: Double?
    public var saliencyAvailable: Bool
}

/// Pure functions mapping raw signals to normalized 0...1 scores using thresholds from
/// `AnalysisConfig`. Centralizing normalization here (rather than in Scoring) keeps the
/// mapping testable in isolation from weighting/aggregation.
public struct SignalNormalizer: Sendable {
    public init() {}

    public func normalize(_ raw: RawSignals) -> NormalizedSignals {
        NormalizedSignals(
            resolution: normalizeResolution(raw.pixelSize),
            sharpness: raw.sharpnessEdgeEnergy.map(normalizeSharpness),
            exposure: normalizeExposure(meanLuma: raw.meanLuma, crushed: raw.crushedShadowFraction, blown: raw.blownHighlightFraction),
            contrast: raw.lumaStdDev.map(normalizeContrast),
            framing: normalizeFraming(areaFraction: raw.subjectAreaFraction, centerOffset: raw.subjectCenterOffset),
            aesthetics: raw.aestheticsScore,
            saliencyAvailable: raw.subjectAreaFraction != nil
        )
    }

    func normalizeResolution(_ size: PixelSize) -> Double {
        let minEdge = Double(size.minEdge)
        if minEdge <= Double(AnalysisConfig.Resolution.unusableMinEdgePixels) { return 0.0 }
        let weak = Double(AnalysisConfig.Resolution.weakMinEdgePixels)
        let excellentMP = AnalysisConfig.Resolution.excellentMegapixels
        // Blend min-edge threshold with megapixel ceiling for a smooth 0...1 curve.
        let edgeScore = min(1.0, minEdge / weak)
        let mpScore = min(1.0, size.megapixels / excellentMP)
        return min(1.0, max(0.0, 0.6 * edgeScore + 0.4 * mpScore))
    }

    func normalizeSharpness(_ edgeEnergy: Double) -> Double {
        let ceiling = AnalysisConfig.Sharpness.normalizationCeiling
        return min(1.0, max(0.0, edgeEnergy / ceiling))
    }

    func normalizeExposure(meanLuma: Double?, crushed: Double?, blown: Double?) -> Double? {
        guard let meanLuma else { return nil }
        let ideal = AnalysisConfig.Exposure.idealMeanLuma
        let distance = abs(meanLuma - ideal) / ideal
        var score = max(0.0, 1.0 - distance)
        if let crushed, crushed > AnalysisConfig.Exposure.crushedShadowFraction {
            score *= 0.4
        }
        if let blown, blown > AnalysisConfig.Exposure.blownHighlightFraction {
            score *= 0.4
        }
        return min(1.0, max(0.0, score))
    }

    func normalizeContrast(_ stdDev: Double) -> Double {
        min(1.0, max(0.0, stdDev / 80.0))
    }

    func normalizeFraming(areaFraction: Double?, centerOffset: Double?) -> Double? {
        guard let areaFraction, let centerOffset else { return nil }
        let minA = AnalysisConfig.Framing.minSubjectAreaFraction
        let maxA = AnalysisConfig.Framing.maxSubjectAreaFraction
        let areaScore: Double
        if areaFraction < minA {
            areaScore = areaFraction / minA
        } else if areaFraction > maxA {
            areaScore = max(0.0, 1.0 - (areaFraction - maxA) / (1.0 - maxA))
        } else {
            areaScore = 1.0
        }
        let centerScore = max(0.0, 1.0 - centerOffset)
        return min(1.0, max(0.0, 0.5 * areaScore + 0.5 * centerScore))
    }
}
