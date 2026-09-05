import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers
@testable import ListingLensQCCore

/// Generates deterministic synthetic test images programmatically, in-memory, as PNG
/// data. No real or copyrighted photos are ever committed to this repository — every
/// fixture used by the test suite is produced by this factory at test-run time.
enum SyntheticImageFactory {

    static func pngData(from image: CGImage) -> Data {
        let data = NSMutableData()
        guard let dest = CGImageDestinationCreateWithData(data, UTType.png.identifier as CFString, 1, nil) else {
            return Data()
        }
        CGImageDestinationAddImage(dest, image, nil)
        CGImageDestinationFinalize(dest)
        return data as Data
    }

    /// A high-frequency checkerboard: sharp edges everywhere, high edge-energy.
    static func sharpCheckerboard(size: Int = 256, cell: Int = 8) -> CGImage {
        render(width: size, height: size) { ctx in
            ctx.setFillColor(CGColor(gray: 1.0, alpha: 1.0))
            ctx.fill(CGRect(x: 0, y: 0, width: size, height: size))
            ctx.setFillColor(CGColor(gray: 0.0, alpha: 1.0))
            var y = 0
            while y < size {
                var x = 0
                while x < size {
                    if ((x / cell) + (y / cell)) % 2 == 0 {
                        ctx.fill(CGRect(x: x, y: y, width: cell, height: cell))
                    }
                    x += cell
                }
                y += cell
            }
        }
    }

    /// A Gaussian-box-blurred version of the checkerboard: low edge-energy.
    static func blurredCheckerboard(size: Int = 256, cell: Int = 8) -> CGImage {
        let sharp = sharpCheckerboard(size: size, cell: cell)
        guard let luma = LumaBuffer.from(cgImage: sharp) else { return sharp }
        var blurred = luma.pixels
        let box = 5
        for y in 0..<luma.height {
            for x in 0..<luma.width {
                var sum = 0, count = 0
                for dy in -box...box {
                    for dx in -box...box {
                        let nx = x + dx, ny = y + dy
                        if nx >= 0, ny >= 0, nx < luma.width, ny < luma.height {
                            sum += Int(luma[nx, ny]); count += 1
                        }
                    }
                }
                blurred[y * luma.width + x] = UInt8(sum / count)
            }
        }
        return renderGray(width: luma.width, height: luma.height, pixels: blurred)
    }

    /// Tiny resolution image (below the "unusable" threshold).
    static func tinyResolution() -> CGImage {
        render(width: 100, height: 80) { ctx in
            ctx.setFillColor(CGColor(gray: 0.5, alpha: 1.0))
            ctx.fill(CGRect(x: 0, y: 0, width: 100, height: 80))
        }
    }

    /// High resolution flat-gray image.
    static func highResolution(width: Int = 2400, height: Int = 1800) -> CGImage {
        render(width: width, height: height) { ctx in
            ctx.setFillColor(CGColor(gray: 0.6, alpha: 1.0))
            ctx.fill(CGRect(x: 0, y: 0, width: width, height: height))
            ctx.setFillColor(CGColor(gray: 0.3, alpha: 1.0))
            ctx.fill(CGRect(x: width / 4, y: height / 4, width: width / 2, height: height / 2))
        }
    }

    /// Very dark, underexposed image.
    static func darkImage(size: Int = 256) -> CGImage {
        render(width: size, height: size) { ctx in
            ctx.setFillColor(CGColor(gray: 0.03, alpha: 1.0))
            ctx.fill(CGRect(x: 0, y: 0, width: size, height: size))
        }
    }

    /// Very bright, overexposed image.
    static func overexposedImage(size: Int = 256) -> CGImage {
        render(width: size, height: size) { ctx in
            ctx.setFillColor(CGColor(gray: 0.98, alpha: 1.0))
            ctx.fill(CGRect(x: 0, y: 0, width: size, height: size))
        }
    }

    /// A single well-lit centered subject image (for framing comparisons).
    static func centralSubjectImage(size: Int = 256) -> CGImage {
        render(width: size, height: size) { ctx in
            ctx.setFillColor(CGColor(gray: 0.85, alpha: 1.0))
            ctx.fill(CGRect(x: 0, y: 0, width: size, height: size))
            ctx.setFillColor(CGColor(gray: 0.2, alpha: 1.0))
            let s = size / 3
            ctx.fillEllipse(in: CGRect(x: (size - s) / 2, y: (size - s) / 2, width: s, height: s))
        }
    }

    /// Same subject placed at the extreme edge of the frame (worse framing).
    static func edgeSubjectImage(size: Int = 256) -> CGImage {
        render(width: size, height: size) { ctx in
            ctx.setFillColor(CGColor(gray: 0.85, alpha: 1.0))
            ctx.fill(CGRect(x: 0, y: 0, width: size, height: size))
            ctx.setFillColor(CGColor(gray: 0.2, alpha: 1.0))
            let s = size / 6
            ctx.fillEllipse(in: CGRect(x: 2, y: 2, width: s, height: s))
        }
    }

    /// Two "unrelated" images with very different content (for distinct-classification tests).
    static func unrelatedImageA(size: Int = 256) -> CGImage {
        render(width: size, height: size) { ctx in
            ctx.setFillColor(CGColor(red: 0.9, green: 0.1, blue: 0.1, alpha: 1.0))
            ctx.fill(CGRect(x: 0, y: 0, width: size, height: size))
        }
    }

    static func unrelatedImageB(size: Int = 256) -> CGImage {
        render(width: size, height: size) { ctx in
            ctx.setFillColor(CGColor(red: 0.1, green: 0.2, blue: 0.9, alpha: 1.0))
            ctx.fill(CGRect(x: 0, y: 0, width: size, height: size))
            ctx.setFillColor(CGColor(red: 0.9, green: 0.9, blue: 0.1, alpha: 1.0))
            for i in stride(from: 0, to: size, by: 20) {
                ctx.fill(CGRect(x: i, y: 0, width: 4, height: size))
            }
        }
    }

    /// A near-duplicate of `centralSubjectImage` with a tiny brightness shift.
    static func nearDuplicateOfCentralSubject(size: Int = 256) -> CGImage {
        render(width: size, height: size) { ctx in
            ctx.setFillColor(CGColor(gray: 0.83, alpha: 1.0))
            ctx.fill(CGRect(x: 0, y: 0, width: size, height: size))
            ctx.setFillColor(CGColor(gray: 0.22, alpha: 1.0))
            let s = size / 3
            ctx.fillEllipse(in: CGRect(x: (size - s) / 2 + 2, y: (size - s) / 2, width: s, height: s))
        }
    }

    private static func render(width: Int, height: Int, draw: (CGContext) -> Void) -> CGImage {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let ctx = CGContext(
            data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0,
            space: colorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )!
        draw(ctx)
        return ctx.makeImage()!
    }

    private static func renderGray(width: Int, height: Int, pixels: [UInt8]) -> CGImage {
        var mutable = pixels
        let colorSpace = CGColorSpaceCreateDeviceGray()
        let ctx = CGContext(
            data: &mutable, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width,
            space: colorSpace, bitmapInfo: CGImageAlphaInfo.none.rawValue
        )!
        return ctx.makeImage()!
    }
}
