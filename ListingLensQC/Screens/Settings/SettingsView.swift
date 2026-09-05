import SwiftUI
#if canImport(ListingLensQCCore)
import ListingLensQCCore
#endif

struct SettingsView: View {
    @EnvironmentObject private var theme: AppTheme
    @State private var accent: AppAccent = .lens

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
                Picker("Accent", selection: $accent) {
                    ForEach(AppAccent.allCases) { a in
                        Text(a.rawValue.capitalized).tag(a)
                    }
                }
                .accessibilityIdentifier("settings.accentPicker")
            }
            Section {
                NavigationLink("About") { AboutView() }
                NavigationLink("Privacy") { PrivacyView() }
            }
        }
        .navigationTitle("Settings")
    }

    private func label(for mode: AppAppearance) -> String {
        switch mode {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        case .black: return "Black"
        }
    }
}
