import Foundation
import CoreGraphics

/// A plain grayscale (luma) pixel buffer extracted from a CGImage, used as the shared
/// input for sharpness, exposure and contrast extraction so we decode/convert once.
/// Pure value type — no platform imaging framework required beyond CoreGraphics, which
/// keeps this file testable outside of a full iOS runtime where CG is available.
public struct LumaBuffer: Sendable {
    public let width: Int
    public let height: Int
    /// Row-major, 1 byte per pixel, 0-255 luma.
    public let pixels: [UInt8]

    public init(width: Int, height: Int, pixels: [UInt8]) {
        self.width = width
        self.height = height
        self.pixels = pixels
    }

    public subscript(x: Int, y: Int) -> UInt8 {
        pixels[y * width + x]
    }

    public static func from(cgImage: CGImage) -> LumaBuffer? {
        let width = cgImage.width
        let height = cgImage.height
        guard width > 0, height > 0 else { return nil }
        var pixels = [UInt8](repeating: 0, count: width * height)
        let colorSpace = CGColorSpaceCreateDeviceGray()
        guard let context = CGContext(
            data: &pixels,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.none.rawValue
        ) else { return nil }
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        return LumaBuffer(width: width, height: height, pixels: pixels)
    }
}
