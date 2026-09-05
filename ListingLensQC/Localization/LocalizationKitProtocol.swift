import Foundation

/// This protocol is deliberately shaped to match the public surface of the (not yet
/// connected) shared `LocalizationKit` repository, so that repository can later be
/// dropped in as the real implementation of `LocalizationService` with no call-site
/// changes anywhere else in the app. See docs/LOCALIZATION.md.
public protocol LocalizationProviding: Sendable {
    /// Returns the localized string for `key` in the given locale identifier, falling
    /// back to English when the key or locale is unavailable.
    func string(for key: String, locale: String) -> String

    /// All locale identifiers this provider can serve, already filtered to exclude any
    /// forbidden locale.
    var supportedLocales: [String] { get }
}

/// Locales that must never appear anywhere in ListingLens QC: not in the registry, not
/// offered in the picker, never selected by device-locale fallback detection. This is a
/// hard product/business constraint, independent of translation completeness.
public enum ForbiddenLocales {
    public static let identifiers: Set<String> = ["ru", "be", "fa-IR", "fa"]

    public static func isForbidden(_ localeIdentifier: String) -> Bool {
        let normalized = localeIdentifier.lowercased()
        return identifiers.contains { normalized == $0.lowercased() || normalized.hasPrefix($0.lowercased() + "-") }
    }
}
