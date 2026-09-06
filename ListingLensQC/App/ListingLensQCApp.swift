import SwiftUI
#if canImport(LocalizationKit)
import LocalizationKit
#endif

@main
struct ListingLensQCApp: App {
    @StateObject private var theme = AppTheme()
    #if canImport(LocalizationKit)
    @State private var localization = AppLocalization.makeManager()
    @Environment(\.scenePhase) private var scenePhase
    #endif

    var body: some Scene {
        WindowGroup {
            ImportView()
                .environmentObject(theme)
                .preferredColorScheme(theme.appearance.colorScheme)
                .background(theme.backgroundColor.ignoresSafeArea())
                #if canImport(LocalizationKit)
                .environment(\.locale, localization.foundationLocale)
                .environment(\.layoutDirection, localization.layoutDirection.isRTL ? .rightToLeft : .leftToRight)
                .environment(localization)
                .onAppear { syncExplanationLocale() }
                .onChange(of: localization.currentLocale) { _, _ in syncExplanationLocale() }
                #endif
        }
        #if canImport(LocalizationKit)
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                localization.refreshFromSystemIfNeeded()
                syncExplanationLocale()
            }
        }
        #endif
    }

    #if canImport(LocalizationKit)
    /// Keeps `LocalizationService` (which drives the dynamic explanation/warning
    /// vocabulary in `ListingLensQCCore` - out of LocalizationKit's scope, see
    /// docs/LOCALIZATION.md) in sync with the single source of truth for "what
    /// language is the app in right now": LocalizationKit's `LocalizationManager`.
    private func syncExplanationLocale() {
        LocalizationService.shared.setLocale(localization.currentLocale.bcp47)
    }
    #endif
}
