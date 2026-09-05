# QA

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
