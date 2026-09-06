import SwiftUI
#if canImport(ListingLensQCCore)
import ListingLensQCCore
#endif
#if canImport(LocalizationKit)
import LocalizationKit
#endif

struct SettingsView: View {
    @EnvironmentObject private var theme: AppTheme

    var body: some View {
        Form {
            Section("Appearance") {
                Picker("Appearance", selection: $theme.appearance) {
                    ForEach(AppAppearance.allCases) { mode in
                        Text(label(for: mode)).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .accessibilityIdentifier("settings.appearancePicker")
            }
            Section("Accent Color") {
                Picker("Accent", selection: $theme.selectedAccent) {
                    ForEach(AppAccent.allCases) { a in
                        Text(accentLabel(for: a)).tag(a)
                    }
                }
                .accessibilityIdentifier("settings.accentPicker")
            }
            #if canImport(LocalizationKit)
            Section("Language") {
                NavigationLink("Language") { AppLanguagePickerView() }
                    .accessibilityIdentifier("settings.languageLink")
            }
            #endif
            Section {
                NavigationLink("About") { AboutView() }
                NavigationLink("Privacy") { PrivacyView() }
            }
        }
        .navigationTitle("Settings")
    }

    private func label(for mode: AppAppearance) -> LocalizedStringKey {
        switch mode {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        case .black: return "Black"
        }
    }

    private func accentLabel(for accent: AppAccent) -> LocalizedStringKey {
        switch accent {
        case .lens: return "Lens"
        case .amber: return "Amber"
        case .violet: return "Violet"
        }
    }
}
