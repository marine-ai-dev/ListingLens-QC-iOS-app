import SwiftUI
import ListingLensQCCore

struct PhotoDetailView: View {
    let score: PhotoScore
    let isHero: Bool
    private let explanations = ExplanationEngine(localization: LocalizationService.shared)

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.md) {
                QualityBadge(score: score.overall)
                if isHero {
                    Label("Best Hero Candidate", systemImage: "star.fill")
                        .foregroundStyle(AppAccent.amber.color)
                }

                Text("\(score.raw.pixelSize.width) × \(score.raw.pixelSize.height) px")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if !score.strengths.isEmpty {
                    sectionHeader("Strengths")
                    ForEach(score.strengths, id: \.self) { key in
                        bullet(explanations.text(forStrengthKey: key), color: StatusColor.good)
                    }
                }

                if !score.warnings.isEmpty {
                    sectionHeader("Warnings")
                    ForEach(score.warnings, id: \.self) { warning in
                        bullet(explanations.text(for: warning), color: StatusColor.warning)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Photo Detail")
        .accessibilityIdentifier("photoDetail.screen")
    }

    private func sectionHeader(_ text: String) -> some View {
        Text(text).font(.headline).padding(.top, Spacing.sm)
    }

    private func bullet(_ text: String, color: Color) -> some View {
        HStack(alignment: .top, spacing: Spacing.sm) {
            Circle().fill(color).frame(width: 8, height: 8).padding(.top, 6)
            Text(text).font(.body)
        }
        .accessibilityElement(children: .combine)
    }
}
