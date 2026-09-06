import SwiftUI
#if canImport(ListingLensQCCore)
import ListingLensQCCore
#endif

struct AnalysisProgressView: View {
    @ObservedObject var viewModel: AuditViewModel
    /// Pops this screen (and, since it was pushed from Import, everything pushed on
    /// top of it - Results included) all the way back to Import in one call. A plain
    /// `@Environment(\.dismiss)` here only pops Progress itself; Results, pushed one
    /// level further, needs to unwind past Progress too, which `dismiss()` alone
    /// cannot do from a screen two levels up the stack.
    let dismissToRoot: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var navigateToResults = false

    var body: some View {
        VStack(spacing: Spacing.lg) {
            if reduceMotion {
                ProgressView(value: viewModel.progress)
                    .accessibilityIdentifier("progress.bar")
            } else {
                ProgressView(value: viewModel.progress)
                    .progressViewStyle(.circular)
                    .scaleEffect(1.6)
                    .accessibilityIdentifier("progress.bar")
            }
            Text("Analyzing \(viewModel.inputs.count) photo(s) on this device…")
                .font(.body)
                .accessibilityLabel(Text("Analyzing \(viewModel.inputs.count) photo(s)"))
            SecondaryButton("Cancel", identifier: "progress.cancelButton") {
                viewModel.cancelAnalysis()
                viewModel.reset()
                dismissToRoot()
            }
            .padding(.horizontal, Spacing.lg)
        }
        .padding()
        .navigationTitle("Analyzing")
        .navigationDestination(isPresented: $navigateToResults) {
            ResultsView(viewModel: viewModel, dismissToRoot: dismissToRoot)
        }
        .onChange(of: viewModel.report != nil) { _, hasReport in
            if hasReport { navigateToResults = true }
        }
    }
}
