# ListingLens QC

**Product Photo Quality Checker** — a native, fully on-device SwiftUI app that helps
online sellers catch bad listing photos before they hurt a sale.

## 📸 What it does

Select 1–20 product photos, get a deterministic 0–100 quality score for each, a plain-
language explanation of what's strong and what's weak, a **Best Hero Candidate**, and a
diversity-aware **Recommended Order** — all computed locally on your device in seconds.

## 🎯 Who it's for

Resellers and small sellers on any marketplace who want a second pair of (automated)
eyes on their photos before they publish a listing — without handing photos to a cloud
service.

## ✨ Highlights

- Deterministic, explainable scoring — every warning is grounded in a real measurement.
- Duplicate/near-duplicate detection that warns, but never auto-deletes.
- A single "Best Hero Candidate" pick, with reasons.
- Fully offline: no accounts, no ads, no analytics, no generative AI.

## 📱 Screens

Import → Analysis Progress → Results → Photo Detail → Recommended Order → Settings →
About → Privacy.

## 🏆 Best Hero Candidate

Not simply the highest-scoring photo — a separate model that rewards quality,
resolution, sharpness, framing, saliency, and aesthetics while penalizing redundancy, so
a near-duplicate of a great shot doesn't win by coincidence. Always exactly one hero for
any non-empty batch. See `docs/SCORING.md`.

## 🔍 Analysis pipeline

Resolution · Sharpness/blur (edge-energy via a Laplacian-style metric) · Exposure
(histogram-based under/over/crushed detection) · Contrast · Vision-based framing/
saliency · Vision image aesthetics as one weighted input. Every stage is deterministic
and unit-tested with synthetic fixtures — see `docs/SCORING.md` for exact formulas.

## 🧩 Similarity & duplicates

Pairwise `VNFeaturePrint` comparison across up to 20 photos, classified as probable
duplicate / very similar / sufficiently distinct against documented, tested thresholds,
and grouped into clusters. Never auto-deletes anything.

## 🧠 Scoring model

One centralized `AnalysisConfig` holds every weight, threshold, and penalty in the app.
Missing signals reduce the denominator of the weighted average rather than being
faked. Full formulas: `docs/SCORING.md`.

## 🔒 Privacy

No networking. No analytics. No accounts. No IAP. No ads. No tracking. No marketplace
API integrations. Full audit: `docs/PRIVACY.md`, plus `Assets/PrivacyInfo.xcprivacy`.

## 🏗 Architecture

`PhotoInput → Decoding → SignalExtraction → Normalization → Similarity → Scoring →
HeroScoring → Ranking → Explanations → UI`, split across two Swift Package targets
(`ListingLensQCCore`, `ListingLensQCUI`) so every stage of the pipeline is unit-testable
without a simulator. Full details: `docs/ARCHITECTURE.md`.

## 🎨 Design system

A local, temporary `DesignSystem/{Theme,Accent,Tokens,Components,Glass,Status}` layer
(`AppTheme`, `AppAccent`, `GlassSurface`, `PrimaryButton`, `SecondaryButton`,
`QualityBadge`, `SettingsRow`, `PhotoCard`), structured so a future shared `DesignKit`
package could replace it without touching any screen.

## 🌐 Localization

The real shared **LocalizationKit** package (`../iOS_localization_kit` locally) is
integrated into the Xcode app target: it owns locale selection, persistence, the
"Use System Language" toggle, and denylist enforcement for `ru`/`be`/`fa`/`fa-IR`
(structurally impossible to select — enforced by `SupportedLocale.init`, not just a
UI-level filter). ListingLens QC's own product copy lives in its own String Catalog,
`Assets/Localizable.xcstrings`, with real translations for the 5 locales this app
ships — **Ukrainian, English, Simplified Chinese, Japanese, and Korean** — covering
every screen's static UI text, not just the dynamic warning/strength vocabulary.
LocalizationKit's own picker lists its full ~40-locale global registry regardless of
a host's configured candidate set, which doesn't fit a 5-locale product, so Settings
uses a small app-owned picker view (`AppLanguagePickerView`) built directly on
`LocalizationManager`/`SupportedLocale` instead — same shared architecture and
persistence, just a picker scoped to what this app actually ships.
The pre-existing local `LocalizationService`/`ExplanationEngine` (dynamic
per-photo warning/strength/hero-reason sentences — outside LocalizationKit's scope)
stays as the single source for that vocabulary, kept in sync with
`LocalizationManager`'s active locale rather than doing its own detection.
See `docs/LOCALIZATION.md` for the full integration writeup.

## ♿ Accessibility

VoiceOver labels/hints, Dynamic Type, Reduce Motion, Reduce Transparency, 44pt touch
targets, and UI test identifiers throughout. Details and honest gaps: `docs/ACCESSIBILITY.md`.

## 🧪 Testing

47 `swift test` unit/integration tests (Analysis, Scoring, Similarity, Localization,
a 20-image stress harness), all against synthetically generated fixtures (no
real/copyrighted photos ever committed). A separate **`ListingLensQCUITests`**
XCUITest target (11 tests) drives the real app in Simulator end-to-end — Import,
the full 1/10/20-photo and duplicate/near-duplicate flows, determinism across two
runs, Settings/About/Privacy, appearance switching, and live language switching —
using a `#if DEBUG`-only synthetic-fixture-injection path (`-UITestFixtureBatch`,
see `docs/QA.md`) instead of driving the real PhotosPicker. Run it from Xcode
(⌘U) or:

```
xcodebuild test -project ListingLensQC.xcodeproj -scheme ListingLensQC \
  -destination 'platform=iOS Simulator,name=iPhone 17'
```

See `docs/QA.md` for exact coverage and what's been manually verified beyond the
automated suites (theme/accent/locale visual matrix, etc).

## 📸 Screenshots

The XCUITest suite attaches a named screenshot (`XCTAttachment`) at each major
screen during its normal run — Import, Analysis Progress, Results, Photo Detail,
Recommended Order, Settings, About, Privacy — using only synthetic fixtures. Pull
them out of the result bundle after a run:

```
xcodebuild test -project ListingLensQC.xcodeproj -scheme ListingLensQC \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -resultBundlePath TestResults.xcresult
xcrun xcresulttool export attachments --path TestResults.xcresult --output-path screenshots/
```

`scripts/capture_screenshots.sh` remains as a lighter-weight alternative that
doesn't need the UI test target at all (boots a Simulator, installs the app, seeds
synthetic fixtures, captures Import, and prints the follow-up `simctl io
screenshot` command for each further screen). No committed screenshot files yet —
see `store/SCREENSHOT_PLAN.md`.

## 🚀 Getting started

```
git clone <this repo>
cd ListingLens-QC-iOS-app
swift build   # SwiftPM library/test targets — requires Xcode 16+ / Swift 5.9+
swift test
```

The real native iOS app target lives in `ListingLensQC.xcodeproj`, generated from
`project.yml` via [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`xcodegen generate`
after editing `project.yml`). Open the `.xcodeproj` in Xcode to build/run on a
Simulator or device. See `docs/RELEASE.md`.

## 🛠 Requirements

- iOS 17.0+
- Xcode 16+ (for the app target / simulator / device builds)
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) to regenerate `ListingLensQC.xcodeproj` after editing `project.yml`
- A local checkout of the shared `iOS_localization_kit` package as a sibling directory
  (`../iOS_localization_kit` relative to this repo) — only required for the Xcode app
  target, not for `swift build`/`swift test`.

## 🗺 Roadmap

- Replace the local `DesignSystem` with a shared `DesignKit` package.
- Wire `scripts/capture_screenshots.sh` up to XCUITest for full screenshot automation.
- Persist past audits locally (currently in-memory only, per session).
- Expand automated screenshot capture once a macOS/Xcode CI runner has actually executed
  `.github/workflows/ios-ci.yml`.

## 🤝 Contributing

See `CONTRIBUTING.md`.

## 📄 License

MIT — see `LICENSE`.
