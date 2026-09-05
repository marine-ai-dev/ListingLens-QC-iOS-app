import Foundation
import CoreGraphics
import ImageIO
#if canImport(UIKit)
import UIKit
#endif

/// A decoded, analysis-ready image: a downsampled CGImage plus the *original* pixel
/// dimensions (read from metadata without ever materializing the full-resolution bitmap).
public struct DecodedImage: Sendable {
    public let photoID: PhotoID
    public let originalSize: PixelSize
    public let analysisImage: CGImage // downsampled to AnalysisConfig.analysisThumbnailMaxEdge

    public init(photoID: PhotoID, originalSize: PixelSize, analysisImage: CGImage) {
        self.photoID = photoID
        self.originalSize = originalSize
        self.analysisImage = analysisImage
    }
}

/// Decodes raw image data into analysis-ready thumbnails using ImageIO's downsampling
/// path (`kCGImageSourceCreateThumbnailFromImageAlways`) so full-resolution bitmaps are
/// never fully decoded into memory for analysis. This keeps peak memory bounded even
/// with 20 photos in a batch.
public struct ImageDecoder: Sendable {
    public init() {}

    public func decode(_ input: PhotoInput) throws -> DecodedImage {
        guard !input.data.isEmpty else { throw AnalysisError.emptyData }
        guard let source = CGImageSourceCreateWithData(input.data as CFData, nil) else {
            throw AnalysisError.decodeFailed
        }
        guard let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
              let width = properties[kCGImagePropertyPixelWidth] as? Int,
              let height = properties[kCGImagePropertyPixelHeight] as? Int,
              width > 0, height > 0 else {
            throw AnalysisError.dimensionsUnavailable
        }
        let originalSize = PixelSize(width: width, height: height)

        let maxEdge = AnalysisConfig.analysisThumbnailMaxEdge
        let thumbnailOptions: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: max(CGFloat(originalSize.minEdge), maxEdge)
        ]
        guard let thumbnail = CGImageSourceCreateThumbnailAtIndex(source, 0, thumbnailOptions as CFDictionary) else {
            throw AnalysisError.decodeFailed
        }
        return DecodedImage(photoID: input.id, originalSize: originalSize, analysisImage: thumbnail)
    }
}
