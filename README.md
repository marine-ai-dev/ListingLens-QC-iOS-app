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

Real translations for English, Ukrainian, Simplified Chinese, Japanese, and Korean.
`ru`, `be`, and `fa`/`fa-IR` are hard-excluded everywhere (registry, picker, fallback),
with regression tests. A shared `LocalizationKit` repository was not connected to this
Cloud session — see `docs/LOCALIZATION.md` for the local integration boundary shipped
in its place.

## ♿ Accessibility

VoiceOver labels/hints, Dynamic Type, Reduce Motion, Reduce Transparency, 44pt touch
targets, and UI test identifiers throughout. Details and honest gaps: `docs/ACCESSIBILITY.md`.

## 🧪 Testing

Unit + integration + a 20-image stress harness, all against synthetically generated
fixtures (no real/copyrighted photos ever committed). See `docs/QA.md` for exact
coverage and what has/hasn't actually been executed in this repository's build
environment.

## 📸 Screenshots

No real UI screenshots exist yet — this repository was authored without Xcode/simulator
access. See `store/SCREENSHOT_PLAN.md` for the planned 7 scenes and the XCUITest
scaffolding approach for capturing them in a future macOS session.

## 🚀 Getting started

```
git clone <this repo>
cd ListingLens-QC-iOS-app
swift build   # requires Xcode 16+ / a Swift 5.9+ toolchain with iOS SDK
swift test
```

To build the actual iOS app (not just the Swift Package), open `Package.swift` in
Xcode 16+ or run `swift package generate-xcodeproj`, then add an App target depending on
`ListingLensQCUI`. See `docs/RELEASE.md`.

## 🛠 Requirements

- iOS 17.0+
- Xcode 16+ (for the app target / simulator / device builds)
- No external dependencies — first-party Apple frameworks only.

## 🗺 Roadmap

- Replace the local `DesignSystem` with a shared `DesignKit` package.
- Replace the local `LocalizationService` with the shared `LocalizationKit` package once
  connected.
- Persist past audits locally (currently in-memory only, per session).
- Expand automated screenshot capture once a macOS/Xcode CI runner has actually executed
  `.github/workflows/ios-ci.yml`.

## 🤝 Contributing

See `CONTRIBUTING.md`.

## 📄 License

MIT — see `LICENSE`.
