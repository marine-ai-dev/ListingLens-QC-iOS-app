# QA

> **Local Simulator phase results (2026-09-06, continued):** the "What has and has
> not run" section below is from the Cloud phase (no Xcode/toolchain available
> there) and is now superseded. Locally, on Xcode 26.6 / iOS 26.5 Simulator
> (iPhone 17 — iPhone 14 is not installed on this Xcode):
>
> - `swift build`/`swift test`: **47 tests, 0 failures**. The Xcode app target
>   builds clean in Debug and Release, no warnings.
> - A real **`ListingLensQCUITests`** XCUITest target now exists (11 tests, all
>   passing, verified across two independent full-suite runs) driving the actual
>   app in Simulator: Import launch; a deterministic 10-photo flow through
>   Results → Photo Detail → Recommended Order → Start New Audit → back to a
>   clean Import; a 20-photo stress flow (no hang, exact 20-count via a
>   scroll-and-collect helper that works around `LazyVGrid`/`List`
>   virtualization); a duplicates+near-duplicate+unrelated 4-photo batch with
>   warning verification; a same-batch-twice determinism check (same hero
>   explanation, same Recommended Order positions/scores); cancel-during-analysis;
>   Settings/About/Privacy content; Appearance persistence across relaunch; all 3
>   accents; the language picker's exact 5-locale scoping (no forbidden locales);
>   and live (no-relaunch) locale switching. Deterministic photo batches are
>   injected via a `#if DEBUG`-only path (`UITestFixtures.swift`,
>   `-UITestFixtureBatch mixed10|stress20|duplicates`) rather than driving the
>   real PhotosPicker grid, which XCUITest cannot do reliably. Verified this path
>   cannot reach Release: `grep`/`strings` on the built Release binary finds zero
>   occurrences of the launch-argument strings.
> - **Real bugs found and fixed by writing/running these UI tests** (not found by
>   manual tapping in the previous pass): "Start New Audit" and "Cancel" reset the
>   view model but never actually popped the navigation stack back to Import,
>   leaving the user stranded on a dead Results/Progress screen — both now use an
>   explicit `dismissToRoot` closure threaded down from `ImportView`. The Hero
>   card and "View Recommended Order" row weren't grouped as single accessible
>   elements (`.accessibilityElement(children: .combine)` was missing), which
>   both broke VoiceOver coherence and made them unfindable by identifier in
>   XCUITest.
> - Visually verified manually beyond the automated suites: Light/Dark/Black
>   appearances and all 3 accents (including live-reactivity and relaunch
>   persistence) across Import/Settings; all 5 shipped locales
>   (uk/en/zh-Hans/ja/ko) across Import/Settings/Results/Photo
>   Detail/About/Privacy with no clipping or untranslated leftovers found; max
>   accessibility Dynamic Type on Import (scrolls correctly, nothing clipped).
> - Not done: a full VoiceOver-narration listen-through (element grouping was
>   verified structurally via the UI tests above, but the actual spoken output
>   was not audited word-by-word), an explicit Reduce Motion toggle-and-exercise
>   pass, and an exhaustive 5-locale × 4-appearance × 8-screen screenshot matrix
>   (the XCUITest suite's `XCTAttachment` screenshots cover 8 screens in the
>   default locale/appearance only). Physical-device testing remains out of scope
>   for this phase.

## Automated coverage (this repository)

- Unit tests: resolution classification, sharpness comparative tests (sharp vs. blurred
  synthetic fixtures), exposure/contrast histogram tests, normalization, scoring
  determinism and range bounds, missing-signal handling, similarity classification
  thresholds and transitive clustering, locale fallback and forbidden-locale exclusion.
- Integration tests: empty batch, 1-photo batch, 20-photo batch, >20 clamping, corrupt
  data, empty data, exact-duplicate flagging (never deletion), cross-run determinism.
- Stress harness: 20 synthetic images of varied character (sharp/blurred/tiny/huge/
  dark/bright/centered/edge-subject/unrelated), asserting completion within a generous
  timeout (no deadlock) and full determinism across two runs. It does **not** assert
  wall-clock or memory numbers — this environment has no real iOS hardware to measure.

Run locally (on a machine with the Swift toolchain — Linux can run the pure-Swift
portions, but `CoreGraphics`/`ImageIO`-backed fixtures and `Vision`-backed extractors
require Apple platforms):

```
swift test
```

## What has and has not run in the cloud session that built this repository

- ✅ Package.swift and all Swift source files were authored and reviewed by hand for
  syntactic/API correctness.
- ❌ `swift build` / `swift test` were **not** executed in this session — there is no
  Swift toolchain, Xcode, or iOS SDK available in this Linux cloud VM (verified via
  `which xcodebuild swift` returning nothing at the start of the session).
- ❌ No simulator boot, no on-device test, no VoiceOver pass occurred.
- ✅ `.github/workflows/ios-ci.yml` was authored to perform exactly this build+test
  cycle on a `macos-15` GitHub Actions runner with a real Xcode toolchain. See
  `COMPLETION_REPORT.md` for whether a run of that workflow was actually observed.

## Manual QA checklist for a future macOS/Xcode session

- [ ] `swift build` and `swift test` pass cleanly with zero warnings-as-errors issues.
- [ ] Generate/open an Xcode project (`swift package generate-xcodeproj` or open
      `Package.swift` directly in Xcode 16+), add an iOS App target wrapping
      `ListingLensQCUI`, and confirm it builds for iOS Simulator.
- [ ] Manually import 1, 2, 20, and >20 photos through `PhotosPicker` and confirm
      graceful clamping/messaging.
- [ ] Manually test VoiceOver across all 8 screens.
- [ ] Manually test Dynamic Type at the largest accessibility size.
- [ ] Manually test Reduce Motion and Reduce Transparency toggles.
- [ ] Run the XCUITest screenshot scaffolding (see `store/SCREENSHOT_PLAN.md`) on a
      booted simulator and capture the 7 required App Store screenshots.
- [ ] Rasterize `Assets/AppIcon/icon.svg` to all required PNG sizes (see the script in
      that folder) and wire up the actual `AppIcon.appiconset`.
