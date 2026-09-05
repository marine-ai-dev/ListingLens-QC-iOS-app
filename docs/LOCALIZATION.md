# Localization

**External integration pending: shared LocalizationKit repository was not connected to
the Cloud session.** `mcp__Claude_Code_Remote__list_repos` was queried for a sibling
`LocalizationKit` repository and returned none, so this app ships a local, temporary
localization implementation instead of depending on the (not yet attached) shared
package.

## What's implemented

- `ListingLensQC/Localization/LocalizationKitProtocol.swift` declares
  `LocalizationProviding`, a protocol deliberately shaped to match the anticipated
  public surface of a shared `LocalizationKit` package (`string(for:locale:)` +
  `supportedLocales`). When that repository becomes available, `LocalizationService` can
  be replaced by an adapter around it with no call-site changes anywhere else in the app.
- `LocalizationService` is the concrete local implementation: an in-memory string
  catalog (no `.strings`/bundle dependency, so it is trivially unit-testable), safe
  locale resolution, and device-locale detection.
- Real (not placeholder/machine-only) translations are shipped for five launch locales:
  **English (en)**, **Ukrainian (uk)**, **Simplified Chinese (zh-Hans)**, **Japanese
  (ja)**, and **Korean (ko)** — see `LocalizationCatalogs.swift`.

## Hard-excluded locales

`ru`, `be`, and `fa`/`fa-IR` are excluded **everywhere**, by construction:

1. **Registry**: `LocalizationCatalogs.all` contains no entries for these locales.
2. **Picker / supported list**: `LocalizationService.supportedLocales` filters through
   `ForbiddenLocales.isForbidden(_:)`, so these locales can never appear in a locale
   picker built from that list.
3. **Fallback / detection**: `LocalizationService.safeLocale(from:)` — used both for an
   explicitly requested locale and for device-locale auto-detection
   (`detectDeviceLocale()`) — always resolves a forbidden identifier (exact match,
   case-insensitive, or matching a `xx-YY` region variant, e.g. `ru-RU`, `be-BY`,
   `fa-IR`) to English, never to another forbidden locale and never left unresolved.
4. **Runtime**: calling `LocalizationService.setLocale("be")` (or any forbidden
   identifier) is silently rejected back to the last safe locale, not applied.

Regression coverage lives in `Tests/ListingLensQCTests/Localization/LocalizationTests.swift`,
including case-insensitivity, region-variant matching (`ru-RU`, `be-BY`), and a test that
every launch-locale catalog contains a translation for every `WarningKind` used by the
scoring engine, so no locale silently falls back to raw English for warning copy at
runtime (falling back to English *text* is fine and by design if a *key* is missing; the
tests instead guard against a translated locale being incomplete).

## Adding a locale later

1. Add its identifier to `LocalizationService.supportedLocaleList` (only if it is not in
   `ForbiddenLocales.identifiers`).
2. Add a full catalog dictionary to `LocalizationCatalogs.all`.
3. Add it to the locale-completeness test loop in `LocalizationTests`.
