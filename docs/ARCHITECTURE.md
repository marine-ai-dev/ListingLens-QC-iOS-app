# Architecture

## Module layout

```
Package.swift
ListingLensQC/
  App/                      # @main entry point (ListingLensQCUI target)
  Analysis/                 # ListingLensQCCore target — pure, testable, Sendable
    PhotoInput/              PhotoInput, PhotoID, AnalysisError, PixelSize
    Decoding/                ImageDecoder (ImageIO downsampled decode)
    SignalExtraction/        LumaBuffer, SharpnessExtractor, ExposureExtractor,
                             FramingExtractor, AestheticsExtractor, RawSignals
    Normalization/           SignalNormalizer -> NormalizedSignals
    Similarity/              SimilarityEngine (VNFeaturePrint), clustering
    Scoring/                 ScoringEngine -> PhotoScore, WarningKind
    HeroScoring/             HeroScoringEngine -> HeroCandidate
    Ranking/                 RecommendedOrderEngine
    Explanations/            ExplanationEngine (raw key -> localized user copy)
    Config/                  AnalysisConfig — single source of truth for every constant
    AnalysisPipeline.swift   Orchestrating actor (bounded concurrency, cancellation)
  DesignSystem/              ListingLensQCCore target — local design layer (see below)
  Localization/              ListingLensQCCore target — LocalizationKit-shaped service
  Screens/                   ListingLensQCUI target — SwiftUI views + thin ViewModels
Tests/ListingLensQCTests/    Unit + integration + stress tests, synthetic fixtures only
```

Two SwiftPM library targets:

- **ListingLensQCCore** — Analysis, Localization, DesignSystem. No SwiftUI View bodies
  with business logic; everything here is a value type or an `actor`/`Sendable` service.
- **ListingLensQCUI** — SwiftUI screens and the `@main` App. Depends on Core, never the
  reverse. Views hold no scoring/ranking/similarity logic themselves — they only render
  `PhotoScore`/`AnalysisReport`/`HeroCandidate` values produced by Core.

This split is deliberate: `ListingLensQCCore` has no UIKit/SwiftUI dependency beyond
what CoreGraphics/Vision themselves require, so its logic is exercised directly by the
`ListingLensQCTests` target without needing a simulator.

## Data flow

`ImportView` (PhotosUI) → `AuditViewModel.startAnalysis()` → `AnalysisPipeline.run(_:)`
(an `actor`) → `AnalysisReport` published back to the view model → `ResultsView` /
`RecommendedOrderView` / `PhotoDetailView` render it.

## Concurrency & memory

- `AnalysisPipeline` is an `actor`; `run(_:)` uses a `TaskGroup` capped at
  `AnalysisConfig.maxConcurrentAnalysisTasks` (4) concurrent decode+analyze tasks, so at
  most 4 downsampled thumbnails are held in memory at once — not all 20 full-resolution
  originals.
- `ImageDecoder` uses `CGImageSourceCreateThumbnailAtIndex` with
  `kCGImageSourceCreateThumbnailFromImageAlways`, which decodes directly to a downsampled
  bitmap without materializing the full-resolution image in memory.
- All decode/signal-extraction work happens off the `MainActor`; only the final
  `AnalysisReport` crosses back to the UI.
- Cancellation: `AuditViewModel.cancelAnalysis()` cancels the driving `Task`;
  `Task.isCancelled` is checked before each unit of work inside the `TaskGroup`.

## Failure handling

Every stage that can fail returns an `AnalysisError` for that single photo rather than
throwing out of the batch. `AnalysisPipeline.run` accumulates `(PhotoID, AnalysisError)`
failures separately from successful `PhotoScore`s — one bad photo never blocks or
invalidates the rest of a 20-photo batch. An empty batch, a 1-photo batch, and a
20-photo batch are all explicitly covered by `AnalysisPipelineIntegrationTests`.

## Design system boundary

`DesignSystem/` is intentionally local and temporary (see the module header comment in
`AppTheme.swift`). It is scoped so that a future shared `DesignKit` package could replace
it file-for-file without touching any Screen — screens only ever reference the semantic
API (`AppTheme`, `AppAccent`, `GlassSurface`, `PrimaryButton`, `SecondaryButton`,
`QualityBadge`, `SettingsRow`, `PhotoCard`), never raw SwiftUI colors or fonts directly.

## Localization boundary

Similarly, `Localization/LocalizationKitProtocol.swift` defines `LocalizationProviding`
shaped to match a hypothetical shared `LocalizationKit` repository's public surface. See
`docs/LOCALIZATION.md` for why this project ships a local implementation instead.
