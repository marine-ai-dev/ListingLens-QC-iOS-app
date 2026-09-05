import SwiftUI

/// A compact badge summarizing a photo's overall score band. Color is never the only
/// signal — a symbol and text label always accompany it for colorblind accessibility.
public struct QualityBadge: View {
    let score: Int

    public init(score: Int) { self.score = score }

    private var band: (label: String, color: Color, symbol: String) {
        switch score {
        case 80...100: return ("Excellent", StatusColor.good, "checkmark.seal.fill")
        case 55..<80: return ("Good", StatusColor.warning, "exclamationmark.circle.fill")
        default: return ("Needs work", StatusColor.critical, "xmark.octagon.fill")
        }
    }

    public var body: some View {
        let b = band
        Label("\(score) · \(b.label)", systemImage: b.symbol)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.xs)
            .background(b.color.opacity(0.18), in: Capsule())
            .foregroundStyle(b.color)
            .accessibilityLabel("Quality score \(score) out of 100, \(b.label)")
    }
}

public struct SettingsRow: View {
    let title: String
    let subtitle: String?
    let icon: String

    public init(title: String, subtitle: String? = nil, icon: String) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
    }

    public var body: some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: icon)
                .frame(width: 28, height: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.body)
                if let subtitle {
                    Text(subtitle).font(.caption).foregroundStyle(.secondary)
                }
            }
            Spacer()
        }
        .frame(minHeight: Metrics.minTouchTarget)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}
