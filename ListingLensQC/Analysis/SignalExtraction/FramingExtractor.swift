import Foundation
import CoreGraphics
#if canImport(Vision)
import Vision
#endif

/// Framing/composition signal via Vision attention-based saliency plus deterministic
/// geometric heuristics (rule-of-thirds distance). This makes no claim to understand
/// *what* the subject is — only where visual attention concentrates in the frame.
public struct FramingExtractor: Sendable {
    public init() {}

    public struct Result: Sendable, Equatable {
        public let subjectAreaFraction: Double
        public let centerOffset: Double // 0 = perfectly on a rule-of-thirds point, 1 = far
    }

    /// Returns nil (rather than a fabricated value) when Vision is unavailable or fails.
    /// A missing framing signal never invalidates the rest of the batch's scoring.
    public func analyze(_ image: CGImage) -> Result? {
        #if canImport(Vision)
        let request = VNGenerateAttentionBasedSaliencyImageRequest()
        let handler = VNImageRequestHandler(cgImage: image, options: [:])
        do {
            try handler.perform([request])
            guard let observation = request.results?.first as? VNSaliencyImageObservation,
                  let object = observation.salientObjects?.first else {
                return nil
            }
            let box = object.boundingBox // normalized, origin bottom-left
            let area = Double(box.width * box.height)
            let centerX = Double(box.midX)
            let centerY = Double(box.midY)
            let thirds: [(Double, Double)] = [(1.0/3, 1.0/3), (2.0/3, 1.0/3), (1.0/3, 2.0/3), (2.0/3, 2.0/3)]
            let bestDistance = thirds.map { pt in
                sqrt(pow(centerX - pt.0, 2) + pow(centerY - pt.1, 2))
            }.min() ?? 1.0
            // Normalize by max possible distance within unit square (~0.745) to 0...1.
            let normalized = min(1.0, bestDistance / 0.745)
            return Result(subjectAreaFraction: area, centerOffset: normalized)
        } catch {
            return nil
        }
        #else
        return nil
        #endif
    }
}

/// Vision image-aesthetics score, used as one weighted input among many — never
/// presented to the user as a raw number, only folded into overall/hero scoring text.
public struct AestheticsExtractor: Sendable {
    public init() {}

    public func score(_ image: CGImage) -> Double? {
        #if canImport(Vision)
        guard #available(iOS 18.0, macOS 15.0, *) else { return nil }
        let request = VNCalculateImageAestheticsScoresRequest()
        let handler = VNImageRequestHandler(cgImage: image, options: [:])
        do {
            try handler.perform([request])
            guard let observation = request.results?.first else { return nil }
            // overallScore is roughly -1...1; normalize to 0...1.
            return Double((observation.overallScore + 1.0) / 2.0)
        } catch {
            return nil
        }
        #else
        return nil
        #endif
    }
}
