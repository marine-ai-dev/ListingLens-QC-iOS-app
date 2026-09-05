import SwiftUI
#if canImport(ListingLensQCCore)
import ListingLensQCCore
#endif

struct ResultsView: View {
    @EnvironmentObject private var theme: AppTheme
    @ObservedObject var viewModel: AuditViewModel
    private let columns = [GridItem(.adaptive(minimum: 150), spacing: Spacing.md)]

    var body: some View {
        ScrollView {
            if let report = viewModel.report {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    if let hero = report.hero {
                        GlassSurface {
                            VStack(alignment: .leading, spacing: Spacing.sm) {
                                Label("Best Hero Candidate", systemImage: "star.fill")
                                    .font(.headline)
                                Text(ExplanationEngine(localization: LocalizationService.shared).heroExplanation(reasons: hero.reasons))
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .accessibilityIdentifier("results.heroCard")
                    }

                    NavigationLink(destination: RecommendedOrderView(viewModel: viewModel)) {
                        Label("View Recommended Order", systemImage: "list.number")
                            .frame(maxWidth: .infinity, minHeight: Metrics.minTouchTarget)
                    }
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: Radius.md))
                    .accessibilityIdentifier("results.recommendedOrderLink")

                    LazyVGrid(columns: columns, spacing: Spacing.md) {
                        ForEach(report.scores) { score in
                            NavigationLink(destination: PhotoDetailView(score: score, isHero: report.hero?.id == score.id, image: viewModel.image(for: score.id))) {
                                PhotoCard(
                                    image: viewModel.image(for: score.id) ?? Image(systemName: "photo"),
                                    score: score.overall,
                                    isHero: report.hero?.id == score.id,
                                    warningCount: score.warnings.count,
                                    identifier: "results.photoCard.\(score.id.value.uuidString)"
                                )
                            }
                        }
                    }

                    if !report.failures.isEmpty {
                        Text("\(report.failures.count) photo(s) could not be analyzed and were skipped.")
                            .font(.footnote)
                            .foregroundStyle(StatusColor.warning)
                    }

                    PrimaryButton("Start New Audit", accent: theme.selectedAccent.color, identifier: "results.newAuditButton") {
                        viewModel.reset()
                    }
                }
                .padding()
            } else {
                Text("No results yet.")
            }
        }
        .navigationTitle("Results")
    }
}
