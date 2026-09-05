import Foundation

/// Converts raw warning/strength/hero-reason keys into cautious, user-facing text.
/// This is the *only* place UI-facing copy for analysis results is generated, and it
/// deliberately avoids semantic-understanding claims ("we detected a shoe") in favor of
/// measurement-grounded language ("sharpness looks lower than the rest of this batch").
public struct ExplanationEngine: Sendable {
    private let localization: LocalizationService
    public init(localization: LocalizationService) {
        self.localization = localization
    }

    public func text(for warning: WarningKind) -> String {
        localization.string(for: "warning.\(warning.rawValue)")
    }

    public func text(forStrengthKey key: String) -> String {
        localization.string(for: key)
    }

    public func heroExplanation(reasons: [String]) -> String {
        reasons.map { localization.string(for: $0) }.joined(separator: " ")
    }
}
