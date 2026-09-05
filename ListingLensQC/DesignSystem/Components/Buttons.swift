import SwiftUI

public struct PrimaryButton: View {
    let title: String
    let accent: Color
    let action: () -> Void
    let identifier: String

    public init(_ title: String, accent: Color = AppAccent.lens.color, identifier: String = "", action: @escaping () -> Void) {
        self.title = title
        self.accent = accent
        self.action = action
        self.identifier = identifier
    }

    public var body: some View {
        Button(action: action) {
            Text(title)
                .font(.body.weight(.semibold))
                .frame(maxWidth: .infinity, minHeight: Metrics.minTouchTarget)
        }
        .background(accent, in: RoundedRectangle(cornerRadius: Radius.md, style: .continuous))
        .foregroundStyle(.white)
        .accessibilityIdentifier(identifier.isEmpty ? "primaryButton.\(title)" : identifier)
        .accessibilityAddTraits(.isButton)
    }
}

public struct SecondaryButton: View {
    let title: String
    let action: () -> Void
    let identifier: String

    public init(_ title: String, identifier: String = "", action: @escaping () -> Void) {
        self.title = title
        self.action = action
        self.identifier = identifier
    }

    public var body: some View {
        Button(action: action) {
            Text(title)
                .font(.body.weight(.medium))
                .frame(maxWidth: .infinity, minHeight: Metrics.minTouchTarget)
        }
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: Radius.md, style: .continuous))
        .accessibilityIdentifier(identifier.isEmpty ? "secondaryButton.\(title)" : identifier)
        .accessibilityAddTraits(.isButton)
    }
}
