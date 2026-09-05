import Foundation

/// Concrete local implementation of `LocalizationProviding`, used until the shared
/// LocalizationKit repository is connected. Backed by an in-memory registry rather than
/// .strings files so it is trivially unit-testable without a bundle/runtime.
public final class LocalizationService: LocalizationProviding, @unchecked Sendable {
    public static let shared = LocalizationService()

    /// The five locales ListingLens QC ships with real translations for at launch.
    public static let supportedLocaleList: [String] = ["en", "uk", "zh-Hans", "ja", "ko"]

    private let catalogs: [String: [String: String]]
    private var currentLocale: String

    public init(preferredLocale: String? = nil) {
        self.catalogs = LocalizationCatalogs.all
        let candidate = preferredLocale ?? Self.detectDeviceLocale()
        self.currentLocale = Self.safeLocale(from: candidate)
    }

    public var supportedLocales: [String] {
        Self.supportedLocaleList.filter { !ForbiddenLocales.isForbidden($0) }
    }

    public var activeLocale: String { currentLocale }

    public func setLocale(_ identifier: String) {
        currentLocale = Self.safeLocale(from: identifier)
    }

    public func string(for key: String) -> String {
        string(for: key, locale: currentLocale)
    }

    public func string(for key: String, locale: String) -> String {
        let safe = Self.safeLocale(from: locale)
        if let value = catalogs[safe]?[key] { return value }
        if let value = catalogs["en"]?[key] { return value }
        return key
    }

    /// Ensures the resolved locale is one of the supported, non-forbidden locales.
    /// A forbidden or unsupported locale always falls back to English — never to another
    /// forbidden locale, and never left unresolved.
    static func safeLocale(from identifier: String) -> String {
        if ForbiddenLocales.isForbidden(identifier) { return "en" }
        if supportedLocaleList.contains(identifier) { return identifier }
        // Try a language-only match (e.g. "zh-Hant" -> not "zh-Hans", falls to en;
        // "ja-JP" -> "ja").
        let lang = identifier.split(separator: "-").first.map(String.init) ?? identifier
        if ForbiddenLocales.isForbidden(lang) { return "en" }
        if let match = supportedLocaleList.first(where: { $0 == lang || $0.hasPrefix(lang + "-") }) {
            return match
        }
        return "en"
    }

    static func detectDeviceLocale() -> String {
        let preferred = Locale.preferredLanguages.first ?? "en"
        return safeLocale(from: preferred)
    }
}
