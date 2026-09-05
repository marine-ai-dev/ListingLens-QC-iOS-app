import SwiftUI
import ListingLensQCCore

struct RecommendedOrderView: View {
    @ObservedObject var viewModel: AuditViewModel

    var body: some View {
        List {
            if let report = viewModel.report {
                ForEach(Array(report.recommendedOrder.enumerated()), id: \.element) { index, id in
                    if let score = report.scores.first(where: { $0.id == id }) {
                        HStack(spacing: Spacing.md) {
                            Text("\(index + 1)")
                                .font(.headline)
                                .frame(width: 28)
                                .accessibilityHidden(true)
                            QualityBadge(score: score.overall)
                            if report.hero?.id == id {
                                Image(systemName: "star.fill").foregroundStyle(AppAccent.amber.color)
                            }
                            Spacer()
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("Position \(index + 1), score \(score.overall)\(report.hero?.id == id ? ", hero photo" : "")")
                        .accessibilityIdentifier("recommendedOrder.row.\(index)")
                    }
                }
            }
        }
        .navigationTitle("Recommended Order")
    }
}
