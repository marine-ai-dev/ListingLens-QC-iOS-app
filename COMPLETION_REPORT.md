# Completion Report — ListingLens QC

> **Local-phase addendum (2026-09-06):** this document is the Cloud phase's
> point-in-time report and is kept as a historical record below. Since it was
> written: a real Xcode app target now exists (`ListingLensQC.xcodeproj`, via
> XcodeGen/`project.yml`); the test suite has grown to **47 tests** (not the 44
> below); the shared `LocalizationKit` package has been integrated for locale
> selection/persistence, with ListingLens QC's own `Assets/Localizable.xcstrings`
> now covering all static UI text across all 5 shipped locales (previously only the
> dynamic explanation vocabulary was translated); and the app has been built,
> launched, and visually verified end-to-end in iOS Simulator. See `docs/LOCALIZATION.md`
> and `docs/QA.md` for current details — do not treat figures below as current.

## Final status

The Cloud phase is complete. A full Swift/SwiftUI source tree for ListingLens QC —
Product Photo Quality Checker — has been authored, documented, and pushed to
`claude/listinglens-qc-ios-040d9j` on `marine-ai-dev/ListingLens-QC-iOS-app`.
`git status` is clean (no untracked or uncommitted files) as of the final push. Remaining
work requires a local macOS/Xcode/iPhone environment — see "Local handoff" below.

## What was implemented

- Full deterministic analysis pipeline: PhotoInput → Decoding → SignalExtraction →
  Normalization → Similarity → Scoring → HeroScoring → Ranking → Explanations → UI,
  split across two SwiftPM library targets (`ListingLensQCCore`, `ListingLensQCUI`).
- All 8 required screens: Import, Analysis Progress, Results, Photo Detail,
  Recommended Order, Settings, About, Privacy — thin SwiftUI views with no business
  logic, backed by a small `AuditViewModel` coordinator.
- Local `DesignSystem/{Theme,Accent,Tokens,Components,Glass,Status}` layer: `AppTheme`,
  `AppAccent`, `GlassSurface`, `PrimaryButton`, `SecondaryButton`, `QualityBadge`,
  `SettingsRow`, `PhotoCard`. System/Light/Dark/Black appearance persisted locally via
  `UserDefaults`. Structured so a future shared `DesignKit` could replace it.
- Local `LocalizationService` behind a `LocalizationKit`-shaped protocol, with real
  translations for English, Ukrainian, Simplified Chinese, Japanese, and Korean, and
  hard exclusion of `ru`/`be`/`fa`/`fa-IR` at the registry, picker, and
  fallback-detection levels (regression-tested).
- `.github/workflows/ios-ci.yml`: checkout → resolve SPM packages → build → determine
  simulator destination → run unit+integration tests → (xcodebuild/UI-test/Release
  steps documented as requiring a generated Xcode project) — targeting `macos-15`.
- Full documentation set (`README.md`, `docs/{ARCHITECTURE,SCORING,PRIVACY,
  ACCESSIBILITY,LOCALIZATION,QA,RELEASE}.md`) and store package
  (`store/{APP_STORE_METADATA,APP_PRIVACY,REVIEW_NOTES,SCREENSHOT_PLAN,
  RELEASE_CHECKLIST}.md`).
- An original SVG app icon (`Assets/AppIcon/icon.svg`, lens/photo-frame/checkmark
  motif) plus a documented rasterization script; `Assets/PrivacyInfo.xcprivacy`;
  `LICENSE` (MIT); `CONTRIBUTING.md`; a Swift/Xcode `.gitignore`.

### Analysis engine specifics

Resolution (ImageIO metadata, no full decode), sharpness (3×3 discrete-Laplacian
edge-energy over a luma buffer), exposure/contrast (256-bin luma histogram), framing
(Vision attention-based saliency + rule-of-thirds distance), aesthetics
(`VNCalculateImageAestheticsScoresRequest`, iOS 18+, one weighted input among several),
and similarity (`VNFeaturePrint` pairwise distance with union-find clustering). Every
threshold and weight is centralized in `AnalysisConfig.swift`; full formulas are in
`docs/SCORING.md`. Hero selection and Recommended Order are separate, deterministic,
tie-broken models — never a plain `max(score)` or raw sort.

## Important bugs found/fixed during this build

All of the following were caught via a real macOS GitHub Actions runner (not guessed) —
see "CI/build results" below for exact run IDs:

1. **`Package.swift` missing a macOS platform entry.** Declaring only `.iOS(.v17)` left
   the implicit macOS deployment target too old for SwiftUI/Vision APIs used throughout
   (`RoundedRectangle`, `.thinMaterial`, `.accessibilityIdentifier`, etc. all require
   macOS 10.15–12.0+), so `swift build` on the macOS CI host failed with dozens of
   "only available in macOS X or newer" errors. **Fix:** added `.macOS(.v14)` alongside
   `.iOS(.v17)` — the shipping app still only ever targets iOS 17+.
2. **Missing `import ListingLensQCCore` in `AboutView.swift` and `PrivacyView.swift`.**
   Both referenced the `Spacing` design token without importing the module it's declared
   in, causing "cannot find 'Spacing' in scope". **Fix:** added the import to both files.
3. **`StressHarnessTests.fullBatch()` passed default-argument factory methods
   (`SyntheticImageFactory.sharpCheckerboard`, etc., which take optional `Int`
   parameters) as bare `() -> CGImage` function references**, which Swift does not allow
   to implicitly resolve defaults — "extra arguments at positions #1, #2 in call".
   **Fix:** wrapped each factory reference in an explicit `{ ... () }` closure.

Additional issues caught by careful reading before any CI run (not compiler-verified,
since no local Swift toolchain exists in the cloud sandbox):
- `Package.swift` originally used both `exclude` and `sources` redundantly on one
  target — simplified to `sources` only.
- `AppTheme.backgroundColor` referenced the UIKit-only `Color(.systemBackground)`
  without a `canImport(UIKit)` guard — fixed with a cross-platform fallback.
- A stress-harness timeout helper originally force-cast `XCTSkip` to `Error`, which does
  not compile — replaced with a dedicated `TimeoutError` type.
- Screen view structs were briefly declared `public` without the explicit `public
  init()` SwiftUI requires — corrected to `internal` (correct, since Screens are only
  consumed within the `ListingLensQCUI` target).

## Exact automated test results

**10 test files, 44 test methods**, under `Tests/ListingLensQCTests/` (plus
`Fixtures/SyntheticImageFactory.swift`, which generates every fixture in-process — no
real or copyrighted photo is ever committed):

| File | Test count |
|---|---|
| `Analysis/SharpnessTests.swift` | 3 |
| `Analysis/ExposureTests.swift` | 4 |
| `Analysis/ResolutionTests.swift` | 4 |
| `Analysis/SimilarityTests.swift` | 4 |
| `Scoring/ScoringDeterminismTests.swift` | 6 |
| `Scoring/HeroAndRankingTests.swift` | 8 |
| `Localization/LocalizationTests.swift` | 7 |
| `Integration/AnalysisPipelineIntegrationTests.swift` | 9 |
| `Integration/StressHarnessTests.swift` | 2 |

**Were they actually run anywhere?** Partially, and only very late in this session, via
the real macOS CI runner described below — not via any local execution:

- This Linux cloud sandbox has **no Swift toolchain at all** (`which swift swiftc
  xcodebuild` returned nothing, checked at the start and end of the session) — nothing
  was compiled or run locally, on Linux or otherwise.
- On the **macOS GitHub Actions runner**, `swift build` reached a clean, successful
  build of both `ListingLensQCCore` and `ListingLensQCUI` (run `33975152578`, step
  "Build package" succeeded at 15:35:47Z) after the platform-declaration fix above.
- `swift test` on that same run then failed to **compile** (not merely fail assertions)
  due to bug #3 above, in `StressHarnessTests.swift`. That was fixed in commit
  `ffe7b8e` and pushed. A follow-up CI run (`33975337735`) was queued/in progress for a
  macOS runner at the time this report was finalized — **its outcome was not observed**
  before wrap-up, per the instruction to stop after fixing what's in flight. So: **the
  full test suite compiling and passing end-to-end has not yet been confirmed by an
  observed CI run** — only that the underlying compile blocker was identified and fixed
  from real compiler output.

## Exact CI/build results (honest)

A **real macOS runner was observed executing** — this is not a claim about an
unobserved workflow. Five runs occurred on `macos-15` GitHub Actions runners against
this branch during the session:

| Run # | Commit | Outcome | Notes |
|---|---|---|---|
| 1 | `e3daf2a` | cancelled | superseded by run 2 (concurrency group) |
| 2 | `9b11475` | failure | `swift build` failed: missing macOS platform declaration |
| 3 | `aaf7d48` | failure | `swift build` failed: missing imports in About/PrivacyView |
| 4 | `53f1e98` | failure | `swift build` **succeeded**; `swift test` failed to compile (StressHarnessTests bug) |
| 5 | `ffe7b8e` | **not observed to completion** | queued/running when this report was finalized |

No Xcode-project-based build, no iOS Simulator boot, no UI test execution, and no
Release archive occurred in any of these runs — the workflow's later steps
(`xcodebuild`, UI tests, Release build) are explicitly scaffolded as documentation of
what a generated Xcode project would need, since this repository ships as a Swift
Package only (see `docs/RELEASE.md`). The `Release Build (signing disabled)` job in run
4 was `skipped` because its dependency job failed.

**Bottom line, stated plainly:** a real macOS/Xcode toolchain did run this code and did
catch three real bugs, which were fixed from actual compiler output. The very latest
fix (`ffe7b8e`) was pushed but its CI outcome was not watched to completion before this
report was finalized, per explicit instruction to wrap up rather than continue
indefinite monitoring.

## Privacy audit result

No networking code anywhere in `ListingLensQC/` (grep for `URLSession|http://|https://`
in source returns no matches). Zero external SwiftPM dependencies. No analytics, ads,
tracking, or account/IAP code. `Assets/PrivacyInfo.xcprivacy` declares only
`NSPrivacyAccessedAPICategoryUserDefaults` (reason `CA92.1`) for the single local
appearance preference. Full writeup: `docs/PRIVACY.md` and `store/APP_PRIVACY.md`.

## Localization audit result

`ru`, `be`, `fa`, and `fa-IR` are excluded from the registry (`LocalizationCatalogs`),
the supported-locale picker list, and locale-fallback/detection
(`LocalizationService.safeLocale(from:)`), including case-insensitive and
region-variant matching (`ru-RU`, `be-BY`). Regression tests exist in
`Tests/ListingLensQCTests/Localization/LocalizationTests.swift` (7 tests) covering
exactly this. **Confirmed to exist and to be part of the suite that reached a
successful build on the macOS CI runner** (run 4's `swift build` succeeded, meaning
`LocalizationTests.swift` compiled cleanly as part of the `ListingLensQCTests` module
that later hit the unrelated `StressHarnessTests` compile error) — but a green
`swift test` run (assertions actually executing and passing) for this or any other test
file has **not** been observed to completion in this session; see the honest note in
"Exact CI/build results" above. No sibling `LocalizationKit` repository was available
(`mcp__Claude_Code_Remote__list_repos` queried with `"LocalizationKit"` returned zero
results), so a local, swappable implementation was built instead — documented in
`docs/LOCALIZATION.md`.

## Accessibility audit result

VoiceOver labels/hints, Dynamic Type via semantic text styles, Reduce Motion (progress
view swaps to a static bar), Reduce Transparency (`GlassSurface` swaps material), 44pt
minimum touch targets, and accessibility identifiers on every interactive control are
implemented per `docs/ACCESSIBILITY.md`. No on-device or Simulator VoiceOver/Dynamic
Type runtime testing has occurred — there is no such runtime in this cloud sandbox.
This is explicitly deferred to local Xcode/device work (see below).

## Repository/branch/final commit/push status

- Repository: `marine-ai-dev/ListingLens-QC-iOS-app`
- Branch: `claude/listinglens-qc-ios-040d9j`
- Final commit at time of this report: `ffe7b8ee6d9f16abdc3a19ff51cd726d8bfd5009`
  ("Fix StressHarnessTests compile error: wrap default-arg factory methods in closures")
- `git status`: clean — no untracked or uncommitted files.
- Push status: all commits pushed successfully to `origin/claude/listinglens-qc-ios-040d9j`.
- No pull request opened; no merge to any default branch, per instructions.
- Commits are grouped by concern (core engine → design system/UI → tests → CI/docs/store
  → completion report → three targeted CI-driven bugfixes), each carrying the required
  `Co-Authored-By`/`Claude-Session` trailer.

## App Store preparation status (real vs. placeholder)

Real: `docs/PRIVACY.md`, `docs/ACCESSIBILITY.md`, `docs/SCORING.md`, and the general
metadata/description drafts in `store/APP_STORE_METADATA.md` and
`store/REVIEW_NOTES.md`. Real: `Assets/PrivacyInfo.xcprivacy` reflecting actual API
usage, and `Assets/AppIcon/icon.svg` as an original vector icon.

Explicitly placeholder/TODO (never fabricated as real): bundle identifier
(`com.example.listinglensqc`), developer account/Team ID, App Store Connect app record,
Support/Marketing/Privacy Policy URLs, rasterized icon PNGs (tooling unavailable in this
sandbox — `rsvg-convert`/`convert`/`inkscape`/`cairosvg` all absent), and all 7 App Store
screenshots (none exist; `store/SCREENSHOT_PLAN.md` specifies the scenes and the
XCUITest-based capture approach for a future macOS session).

## LOCAL HANDOFF — remaining tasks for Xcode + Simulator + physical iPhone

The following were explicitly **not attempted** in this cloud session and must happen
locally:

1. **Confirm a clean `swift test` run.** Open `Package.swift` in Xcode 16+ (or run
   `swift package generate-xcodeproj`), run `swift test`, and confirm all 44 test
   methods pass (the most recent CI-driven fix, commit `ffe7b8e`, was pushed but its
   run was not watched to completion — verify it first).
2. **Wire up the actual iOS App target**: add an App target depending on
   `ListingLensQCUI`, set bundle identifier, deployment target (17.0), and attach
   `Assets/PrivacyInfo.xcprivacy` and the rasterized `AppIcon.appiconset`.
3. **Simulator visual QA**: launch on an iOS Simulator and walk the full flow
   (Import → Progress → Results → Photo Detail → Recommended Order → Settings → About →
   Privacy). This includes confirming layout, spacing, and the Liquid-Glass-inspired
   surfaces actually render as intended — no visual verification has occurred yet.
4. **Real PhotosPicker / photo library test**: import 1, several, 20, and >20 photos
   from an actual photo library (not synthetic fixtures) and confirm the picker,
   loading, and clamping behavior end-to-end.
5. **Final Liquid Glass visual tuning**: adjust `GlassSurface`, blur/material choices,
   and spacing by eye on-device — this was designed but not visually tuned.
6. **Physical-device testing**: run on at least one real iPhone, including:
   - Real-device memory/performance validation for a 20-photo batch (the stress harness
     in this repo only checks completion/determinism in a cloud CI container — it
     explicitly does not and cannot measure real memory/wall-clock behavior).
   - VoiceOver pass across all 8 screens.
   - Dynamic Type at the largest accessibility size.
   - Reduce Motion / Reduce Transparency toggles.
7. **Screenshot capture**: build the XCUITest scaffolding referenced in
   `store/SCREENSHOT_PLAN.md` and capture the 7 required App Store screenshots on a
   booted Simulator or device.
8. **Icon rasterization**: run `Assets/AppIcon/generate_icons.py` (needs `cairosvg` or
   `rsvg-convert`, per its docstring) on a machine that has one, and wire the resulting
   PNGs into an `AppIcon.appiconset`.
9. **Fill remaining TODO placeholders**: real bundle identifier, developer account/Team
   ID, App Store Connect record, and hosted Privacy Policy/Support URLs, per
   `store/RELEASE_CHECKLIST.md`.
10. **Archive and validate** with a real signing identity once all of the above is done.
