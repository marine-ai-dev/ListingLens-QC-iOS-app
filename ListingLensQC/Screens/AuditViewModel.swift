import Foundation
import SwiftUI
#if canImport(ListingLensQCCore)
import ListingLensQCCore
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
            errorMessage = "Select at least one photo to begin."
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

    public func reset() {
        analysisTask?.cancel()
        inputs = []
        report = nil
        isAnalyzing = false
        progress = 0
        errorMessage = nil
    }
}
