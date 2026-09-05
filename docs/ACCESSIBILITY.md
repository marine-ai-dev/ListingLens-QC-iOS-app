# Accessibility

ListingLens QC targets full VoiceOver and Dynamic Type support from a photography-heavy
UI without relying on color alone.

## What's implemented

- **VoiceOver**: every interactive control (`PrimaryButton`, `SecondaryButton`,
  `PhotoCard`, `QualityBadge`, `SettingsRow`) sets an explicit accessibility label and,
  where the action isn't obvious from the label, an accessibility hint (e.g. the hero
  card announces "Recommended hero photo"). Composite rows use
  `.accessibilityElement(children: .combine)` so VoiceOver reads them as one coherent
  unit rather than fragment-by-fragment.
- **Never color-only status**: `QualityBadge` always pairs its color with an SF Symbol
  and a text label ("87 · Excellent"), so colorblind users get the same information
  sighted users relying on color would.
- **Dynamic Type**: all text uses semantic `Font` text styles (`.body`, `.headline`,
  `.caption`, `.largeTitle`) rather than fixed point sizes, so it scales with the user's
  preferred content size.
- **Reduce Motion**: `AnalysisProgressView` swaps its animated circular spinner for a
  static linear `ProgressView` when `accessibilityReduceMotion` is enabled.
- **Reduce Transparency**: `GlassSurface` swaps its `.ultraThinMaterial` for the more
  opaque `.thickMaterial` when `accessibilityReduceTransparency` is enabled.
- **Touch targets**: `Metrics.minTouchTarget = 44` is applied as a minimum frame height
  on every button and settings row, per Apple's Human Interface Guidelines.
- **UI test identifiers**: every primary control carries an
  `.accessibilityIdentifier(...)` (e.g. `import.selectPhotosButton`,
  `results.heroCard`, `settings.appearancePicker`) so UI tests (and VoiceOver custom
  rotors) can address them reliably.

## Known gaps (honest accounting)

- No physical device or VoiceOver runtime testing has occurred in this cloud
  environment — there is no accessible iOS runtime here to test against. The
  implementation follows documented Apple HIG/accessibility API contracts, but a
  pre-release manual VoiceOver pass on-device is still required (tracked in
  `docs/QA.md`).
- Localized VoiceOver labels currently reuse the same English base strings used in
  warnings/strengths for hint text; a full accessibility-specific localization pass is a
  candidate for a follow-up release.
