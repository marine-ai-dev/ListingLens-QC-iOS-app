import Foundation

/// Histogram-based exposure and contrast measurement. Deterministic and pure.
public struct ExposureExtractor: Sendable {
    public init() {}

    public struct Result: Sendable, Equatable {
        public let meanLuma: Double
        public let stdDev: Double
        public let crushedShadowFraction: Double
        public let blownHighlightFraction: Double
    }

    public func analyze(_ buffer: LumaBuffer) -> Result? {
        guard !buffer.pixels.isEmpty else { return nil }
        var histogram = [Int](repeating: 0, count: 256)
        for p in buffer.pixels { histogram[Int(p)] += 1 }
        let total = Double(buffer.pixels.count)

        var sum: Double = 0
        for (value, count) in histogram.enumerated() { sum += Double(value) * Double(count) }
        let mean = sum / total

        var varianceSum: Double = 0
        for (value, count) in histogram.enumerated() {
            let diff = Double(value) - mean
            varianceSum += diff * diff * Double(count)
        }
        let stdDev = sqrt(varianceSum / total)

        // Bottom/top 3% of the 0-255 range (~bins 0-7 and 248-255).
        let shadowBinCount = 8
        let highlightBinStart = 256 - shadowBinCount
        let shadowCount = histogram[0..<shadowBinCount].reduce(0, +)
        let highlightCount = histogram[highlightBinStart..<256].reduce(0, +)

        return Result(
            meanLuma: mean,
            stdDev: stdDev,
            crushedShadowFraction: Double(shadowCount) / total,
            blownHighlightFraction: Double(highlightCount) / total
        )
    }
}
