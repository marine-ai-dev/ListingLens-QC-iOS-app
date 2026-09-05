# Screenshot Plan

This cloud session has no Xcode/iOS Simulator, so no real UI screenshots could be
rendered or captured. **No screenshot images are included in this repository** — none
were fabricated. This document specifies the 7 required scenes and where the automation
to capture them (once a macOS/Xcode session is available) should live.

## Required scenes

1. **Import** — the initial screen with the "Select Photos" call to action.
2. **Analysis Progress** — mid-analysis, showing the progress indicator and photo count.
3. **Results overview** — the grid of scored photos with the Best Hero Candidate card
   visible at the top.
4. **Photo Detail** — one photo's detail view, showing strengths and warnings text.
5. **Recommended Order** — the ranked list view with the hero pinned to position 1.
6. **Settings** — appearance (System/Light/Dark/Black) and accent color pickers.
7. **Privacy** — the in-app privacy explanation screen.

## Capture automation

XCUITest-based capture should live in a new `ListingLensQCUITests` test target (added
once an Xcode project exists — see `docs/RELEASE.md`), using
`XCUIScreen.main.screenshot()` / `XCTAttachment` at each of the 7 scenes above, driven by
the `accessibilityIdentifier`s already present in every screen (e.g.
`import.selectPhotosButton`, `results.heroCard`, `recommendedOrder.row.0`,
`settings.appearancePicker`) so the automation does not depend on brittle coordinate
taps or text matching.

## Status

- [x] Scenes specified.
- [x] Accessibility identifiers already present in the shipped SwiftUI views to support
      driving these scenes from XCUITest.
- [ ] XCUITest target scaffolded (requires an Xcode project, not just Package.swift).
- [ ] Actual screenshots captured on a booted iOS Simulator or device — **requires a
      future macOS/Xcode session**.
