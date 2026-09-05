import SwiftUI
import ListingLensQCCore

struct AnalysisProgressView: View {
    @ObservedObject var viewModel: AuditViewModel
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
            Text("Analyzing \(viewModel.inputs.count) photo\(viewModel.inputs.count == 1 ? "" : "s") on this device…")
                .font(.body)
                .accessibilityLabel("Analyzing \(viewModel.inputs.count) photos")
            SecondaryButton("Cancel", identifier: "progress.cancelButton") {
                viewModel.cancelAnalysis()
            }
            .padding(.horizontal, Spacing.lg)
        }
        .padding()
        .navigationTitle("Analyzing")
        .navigationDestination(isPresented: $navigateToResults) {
            ResultsView(viewModel: viewModel)
        }
        .onChange(of: viewModel.report != nil) { _, hasReport in
            if hasReport { navigateToResults = true }
        }
    }
}
