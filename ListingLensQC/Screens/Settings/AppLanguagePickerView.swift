#if canImport(LocalizationKit)
import SwiftUI
import LocalizationKit

/// ListingLens QC's own language picker view.
///
/// `LocalizationKit.LanguagePickerView` lists its full global registry regardless of
/// `Configuration.candidates` (it reads `LocaleRegistry.pinned`/`.entries(in:)`
/// directly), which is wrong for this app: ListingLens ships real product-string
/// translations for exactly 5 locales (see `Assets/Localizable.xcstrings`), so
/// offering the other ~40 registry entries would silently fall back to English for
/// all product copy while claiming a different language is selected.
///
/// This view reuses every part of the real shared architecture that *is* scoped
/// correctly - `LocalizationManager`, `SupportedLocale`, persistence, denylist
/// enforcement, and even LocalizationKit's own translated picker strings (`L10n.Picker`)
/// - and only replaces the row list with `manager.allLocales`, which already reflects
/// the `AppLocalization.supportedLocaleIDs` restriction.
struct AppLanguagePickerView: View {
    @Environment(LocalizationManager.self) private var manager

    var body: some View {
        List {
            Section {
                Button {
                    manager.useSystemLanguage()
                } label: {
                    HStack {
                        Text(L10n.Picker.useSystemLanguage)
                        Spacer()
                        if manager.isUsingSystemLanguage {
                            Image(systemName: "checkmark")
                        }
                    }
                }
                .accessibilityElement(children: .combine)
                .accessibilityIdentifier("language.useSystemLanguage")
            }

            Section {
                ForEach(manager.allLocales) { locale in
                    Button {
                        manager.select(locale)
                    } label: {
                        HStack {
                            if let flag = locale.flagEmoji {
                                Text(flag)
                            }
                            VStack(alignment: .leading) {
                                Text(locale.nativeName)
                                    .foregroundStyle(.primary)
                                if locale.nativeName != locale.englishName {
                                    Text(locale.englishName)
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                            if !manager.isUsingSystemLanguage && manager.currentLocale.id == locale.id {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityIdentifier("language.option.\(locale.id)")
                }
            }
        }
        .navigationTitle(Text(L10n.Picker.chooseLanguage))
    }
}
#endif
