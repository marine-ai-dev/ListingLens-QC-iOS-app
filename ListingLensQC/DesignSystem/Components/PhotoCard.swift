import SwiftUI

/// Card representing one analyzed photo in the Results/Recommended Order grids.
public struct PhotoCard: View {
    let image: Image
    let score: Int
    let isHero: Bool
    let warningCount: Int
    let identifier: String

    public init(image: Image, score: Int, isHero: Bool, warningCount: Int, identifier: String) {
        self.image = image
        self.score = score
        self.isHero = isHero
        self.warningCount = warningCount
        self.identifier = identifier
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            ZStack(alignment: .topTrailing) {
                image
                    .resizable()
                    .aspectRatio(1, contentMode: .fill)
                    .clipShape(RoundedRectangle(cornerRadius: Radius.md, style: .continuous))
                if isHero {
                    Label("Hero", systemImage: "star.fill")
                        .font(.caption2.weight(.bold))
                        .padding(.horizontal, Spacing.sm)
                        .padding(.vertical, 4)
                        .background(AppAccent.amber.color, in: Capsule())
                        .foregroundStyle(.white)
                        .padding(Spacing.xs)
                }
            }
            HStack {
                QualityBadge(score: score)
                if warningCount > 0 {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(StatusColor.warning)
                        .accessibilityLabel("\(warningCount) warnings")
                }
            }
        }
        .accessibilityIdentifier(identifier)
        .accessibilityElement(children: .combine)
        .accessibilityHint(isHero ? Text("Recommended hero photo") : Text(""))
    }
}
