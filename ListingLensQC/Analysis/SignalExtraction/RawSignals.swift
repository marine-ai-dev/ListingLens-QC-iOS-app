import Foundation

/// Raw, un-normalized measurements extracted from a single photo. Any signal that could
/// not be computed is `nil` rather than a fabricated value — see `MissingSignalPolicy`.
public struct RawSignals: Sendable, Equatable {
    public var pixelSize: PixelSize
    public var sharpnessEdgeEnergy: Double?      // Laplacian/edge-energy metric
    public var meanLuma: Double?                 // 0-255
    public var lumaStdDev: Double?                // contrast
    public var crushedShadowFraction: Double?
    public var blownHighlightFraction: Double?
    public var subjectAreaFraction: Double?       // Vision saliency bounding box / image area
    public var subjectCenterOffset: Double?       // normalized distance from rule-of-thirds points
    public var aestheticsScore: Double?           // Vision image aesthetics, 0-1
    public var visionAvailable: Bool

    public init(
        pixelSize: PixelSize,
        sharpnessEdgeEnergy: Double? = nil,
        meanLuma: Double? = nil,
        lumaStdDev: Double? = nil,
        crushedShadowFraction: Double? = nil,
        blownHighlightFraction: Double? = nil,
        subjectAreaFraction: Double? = nil,
        subjectCenterOffset: Double? = nil,
        aestheticsScore: Double? = nil,
        visionAvailable: Bool = true
    ) {
        self.pixelSize = pixelSize
        self.sharpnessEdgeEnergy = sharpnessEdgeEnergy
        self.meanLuma = meanLuma
        self.lumaStdDev = lumaStdDev
        self.crushedShadowFraction = crushedShadowFraction
        self.blownHighlightFraction = blownHighlightFraction
        self.subjectAreaFraction = subjectAreaFraction
        self.subjectCenterOffset = subjectCenterOffset
        self.aestheticsScore = aestheticsScore
        self.visionAvailable = visionAvailable
    }
}
