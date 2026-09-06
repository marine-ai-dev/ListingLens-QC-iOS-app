import Foundation
import SwiftUI
#if canImport(ListingLensQCCore)
import ListingLensQCCore
#endif
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// Thin, testable coordinator holding no business logic itself — it only calls into
/// `AnalysisPipeline` (Core) and republishes state for the views. All scoring/ranking
/// decisions live in Core, never here.
@MainActor
public final class AuditViewModel: ObservableObject {
    @Published public var inputs: [PhotoInput] = []
    @Published public var isAnalyzing = false
    @Published public var progress: Double = 0
    @Published public var report: AnalysisReport?
    @Published public var errorMessage: String?

    private var analysisTask: Task<Void, Never>?
    private let pipeline = AnalysisPipeline()

    public init() {}

    public func startAnalysis() {
        guard !inputs.isEmpty else {
            errorMessage = String(localized: "Select at least one photo to begin.")
            return
        }
        isAnalyzing = true
        progress = 0
        analysisTask = Task {
            let result = await pipeline.run(inputs)
            if !Task.isCancelled {
                self.report = result
                self.isAnalyzing = false
                self.progress = 1.0
            }
        }
    }

    public func cancelAnalysis() {
        analysisTask?.cancel()
        isAnalyzing = false
    }

    /// Decodes the original selected photo for display. Views never hold decoded
    /// images themselves — `inputs` (raw `Data`) is the only source of truth, matching
    /// `PhotoInput`'s "never crosses actor boundaries holding a UIImage" contract.
    public func image(for id: PhotoID) -> Image? {
        guard let data = inputs.first(where: { $0.id == id })?.data else { return nil }
        #if canImport(UIKit)
        guard let platformImage = UIImage(data: data) else { return nil }
        return Image(uiImage: platformImage)
        #elseif canImport(AppKit)
        guard let platformImage = NSImage(data: data) else { return nil }
        return Image(nsImage: platformImage)
        #else
        return nil
        #endif
    }

    public func reset() {
        analysisTask?.cancel()
        inputs = []
        report = nil
        isAnalyzing = false
        progress = 0
        errorMessage = nil
    }
}
