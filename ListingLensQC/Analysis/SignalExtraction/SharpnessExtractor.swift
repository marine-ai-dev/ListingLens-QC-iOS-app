import Foundation
#if canImport(Accelerate)
import Accelerate
#endif

/// Computes a deterministic edge-energy ("variance of Laplacian"-style) sharpness metric
/// from a luma buffer. Higher values indicate more high-frequency edge content, which
/// correlates with in-focus, sharp photos; near-zero values indicate blur/flatness.
///
/// This is a pure, synchronous, testable value operation with no I/O — it is the single
/// place the app measures blur, so comparative unit tests (sharp vs. blurred synthetic
/// fixtures) exercise exactly this code path.
public struct SharpnessExtractor: Sendable {
    public init() {}

    public func edgeEnergy(of buffer: LumaBuffer) -> Double? {
        let w = buffer.width, h = buffer.height
        guard w >= 3, h >= 3 else { return nil }

        // 3x3 Laplacian kernel: [[0,1,0],[1,-4,1],[0,1,0]]
        var sumSquares: Double = 0
        var count: Double = 0
        for y in 1..<(h - 1) {
            for x in 1..<(w - 1) {
                let center = Double(buffer[x, y])
                let up = Double(buffer[x, y - 1])
                let down = Double(buffer[x, y + 1])
                let left = Double(buffer[x - 1, y])
                let right = Double(buffer[x + 1, y])
                let laplacian = up + down + left + right - 4 * center
                sumSquares += laplacian * laplacian
                count += 1
            }
        }
        guard count > 0 else { return nil }
        let variance = sumSquares / count
        // Scale down to keep numbers in a human-legible range comparable to AnalysisConfig thresholds.
        return sqrt(variance)
    }
}
