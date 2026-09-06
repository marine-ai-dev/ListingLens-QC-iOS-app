# Localization

**The real shared `LocalizationKit` package is integrated**, found locally at
`../iOS_localization_kit` (sibling checkout to this repo) and wired into the Xcode app
target (`ListingLensQC.xcodeproj`, via `project.yml` -> `packages.LocalizationKit`).
It is *not* a dependency of the SwiftPM `Package.swift` used by `swift build`/`swift
test`/CI — those don't need it and stay dependency-free — so every reference to it in
app-target-only source files (`ListingLensQC/App/*.swift`,
`ListingLensQC/Screens/Settings/*.swift`) is guarded with `#if canImport(LocalizationKit)`.

## What LocalizationKit owns

- `LocalizationManager` (`@Observable`): current locale, "Use System Language" vs.
  manual override, persistence (`UserDefaults`), and re-resolution on foreground.
  Created once in `ListingLensQCApp` via `AppLocalization.makeManager()` and injected
  app-wide with `.environment(localization)` / `.environment(\.locale, ...)`.
- `SupportedLocale` / `LocaleRegistry`: the locale model and its ~40-locale global
  registry. `AppLocalization.supportedLocaleIDs` restricts this app's `Configuration
  .candidates` to the 5 locales ListingLens QC actually ships translations for
  (`pinned.uk`, `pinned.en-US`, `ea.zh-Hans`, `ea.ja-JP`, `ea.ko-KR`) — `manager
  .allLocales` reflects exactly that restricted set.
- `ExcludedLocaleDenylist`: `ru`/`be`/`fa` (and region variants like `fa-IR`) are
  denied at the model level — `SupportedLocale.init` itself preconditions against a
  denied identifier, so a denylisted locale cannot exist as a registry entry, let
  alone be selected. This is stronger than a UI-level filter.

## Why Settings doesn't use `LocalizationKit.LanguageSettingsView` directly

`LocalizationKit.LanguagePickerView` renders `LocaleRegistry.pinned` and
`LocaleRegistry.entries(in:)` directly — it does **not** consult
`manager.allLocales`/`Configuration.candidates` when building its row list. That's
reasonable for a host app that ships all ~40 locales, but wrong for ListingLens QC,
which only has real product-string translations for 5: showing the other ~35 would
let a user "select" e.g. Croatian and see the app silently stay in English for every
screen while Settings claims Croatian is active.

`ListingLensQC/Screens/Settings/AppLanguagePickerView.swift` is a small app-owned
picker view instead: it reuses `LocalizationManager`, `SupportedLocale`, persistence,
and even LocalizationKit's own already-translated picker strings (`L10n.Picker.*`),
and only replaces the row list with `manager.allLocales` (already correctly scoped).
This is "one architecture, one picker view" — not two competing localization systems.

## ListingLens QC's own product strings

Per LocalizationKit's integration guide ("own your product strings"),
`Assets/Localizable.xcstrings` is ListingLens QC's own String Catalog, with real
translations for all 5 shipped locales covering every screen's static UI text:
titles, buttons, section headers, empty/error states, accessibility labels/hints.
SwiftUI's `Text`/`Label`/`.navigationTitle`/`.accessibilityLabel` etc. resolve string
*literals* against this catalog automatically; the app also fixes several spots that
used to build plain `String`s (verbatim, never localized) instead of
`LocalizedStringKey` — the Appearance segmented picker's labels, the Accent picker's
option names, `QualityBadge`'s status text ("Excellent"/"Good"/"Needs work"), and
`PrimaryButton`/`SecondaryButton`'s title parameter — all found by actually switching
the running app's language in Simulator and watching what stayed in English.

The pre-existing `LocalizationService` + `LocalizationCatalogs` (in
`ListingLensQC/Localization/`) is **not** duplicated architecture — it covers a
different, narrower thing: the *dynamic* per-photo explanation vocabulary
(`ExplanationEngine`'s warning/strength/hero-reason sentences), which is
product-specific business logic outside LocalizationKit's scope, not app chrome.
`ListingLensQCApp` keeps it in sync by calling
`LocalizationService.shared.setLocale(localization.currentLocale.bcp47)` whenever
`LocalizationManager`'s locale changes (on appear, on change, and on foreground) —
one source of truth for "what language is the app in," two catalogs for two
different kinds of text.

## Hard-excluded locales

`ru`, `be`, and `fa`/`fa-IR` are excluded **everywhere**, by construction, at two
independent layers:

1. **LocalizationKit layer** (language picker / system-language detection):
   `ExcludedLocaleDenylist` — enforced at `SupportedLocale.init`, so a denied locale
   cannot exist in the registry passed to `AppLanguagePickerView` or resolved by
   `LocalizationManager.refreshFromSystemIfNeeded()`.
2. **Explanation-vocabulary layer** (`ExplanationEngine`'s dynamic text):
   `ForbiddenLocales` + `LocalizationService.safeLocale(from:)`, unchanged from
   before — always resolves a forbidden identifier (exact match, case-insensitive,
   or a `xx-YY` region variant) to English.

Regression coverage: `Tests/ListingLensQCTests/Localization/LocalizationTests.swift`
(case-insensitivity, region-variant matching, per-locale warning-catalog
completeness) plus LocalizationKit's own test suite (`DenylistTests.swift`,
`RegistryTests.swift` in `iOS_localization_kit/Tests/`), which precondition-tests
that a denied `SupportedLocale` cannot be constructed at all.

## Verified in Simulator this pass

Import, Settings (Appearance/Accent/Language rows), Results, Photo Detail, About, and
Privacy were visually inspected on iPhone 17 in Ukrainian, Simplified Chinese,
Japanese, and Korean (English is the default/source language, verified throughout
every other pass) — no truncation, clipping, or untranslated leftovers found across
those screens/locales. Recommended Order and Analysis Progress were verified via
their localized navigation title / interpolated progress string appearing correctly
in Ukrainian; the full 5x8 screen matrix was not exhaustively screenshotted.

## Adding a locale later

1. Add the `SupportedLocale.id` to `AppLocalization.supportedLocaleIDs`
   (`ListingLensQC/App/AppLocalization.swift`) — only if it's not in
   `ExcludedLocaleDenylist.deniedBaseLanguages` (enforced automatically either way).
2. Add a full translation set to `Assets/Localizable.xcstrings` for every key.
3. Add a full catalog dictionary to `LocalizationCatalogs.all` (dynamic explanation
   vocabulary) and to the locale-completeness test loop in `LocalizationTests`.
