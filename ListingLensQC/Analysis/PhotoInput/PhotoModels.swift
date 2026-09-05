import Foundation
import CoreGraphics

/// Opaque, Sendable identifier for a photo within a single audit batch.
public struct PhotoID: Hashable, Sendable, Codable {
    public let value: UUID
    public init(_ value: UUID = UUID()) { self.value = value }
}

/// A single photo as it enters the pipeline: raw bytes only, no decoding performed yet.
/// Never crosses actor boundaries holding a UIImage — decoding happens in `Decoding`.
public struct PhotoInput: Sendable, Identifiable {
    public var id: PhotoID
    public let data: Data
    public let originalFilename: String?

    public init(id: PhotoID = PhotoID(), data: Data, originalFilename: String? = nil) {
        self.id = id
        self.data = data
        self.originalFilename = originalFilename
    }
}

/// Errors that can occur anywhere in the pipeline. A single photo's failure never
/// invalidates the rest of the batch (see `AnalysisReport.perPhotoFailures`).
public enum AnalysisError: Error, Sendable, Equatable {
    case emptyData
    case decodeFailed
    case unsupportedFormat
    case visionUnavailable
    case cancelled
    case dimensionsUnavailable
}

/// Pixel dimensions of a decoded image.
public struct PixelSize: Sendable, Equatable, Codable {
    public let width: Int
    public let height: Int
    public init(width: Int, height: Int) { self.width = width; self.height = height }
    public var minEdge: Int { min(width, height) }
    public var maxEdge: Int { max(width, height) }
    public var pixelCount: Int { width * height }
    public var megapixels: Double { Double(pixelCount) / 1_000_000.0 }
    public var aspectRatio: Double { height == 0 ? 0 : Double(width) / Double(height) }
}
