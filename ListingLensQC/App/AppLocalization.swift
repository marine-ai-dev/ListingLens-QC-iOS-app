#if canImport(LocalizationKit)
import Foundation
import LocalizationKit

/// ListingLens QC's integration point for the shared `LocalizationKit` package.
///
/// The kit's own registry spans dozens of locales; this app only ships real product
/// translations for 5 (see `Assets/Localizable.xcstrings` and
/// `ListingLensQC/Localization/LocalizationCatalogs.swift`), so the picker is
/// restricted to exactly that set via `Configuration.candidates` rather than exposing
/// the full global registry.
enum AppLocalization {
    static let supportedLocaleIDs: Set<String> = [
        "pinned.uk", "pinned.en-US", "ea.zh-Hans", "ea.ja-JP", "ea.ko-KR"
    ]

    @MainActor
    static func makeManager() -> LocalizationManager {
        let candidates = LocaleRegistry.all.filter { supportedLocaleIDs.contains($0.id) }
        return LocalizationManager(configuration: .init(candidates: candidates))
    }
}
#endif
