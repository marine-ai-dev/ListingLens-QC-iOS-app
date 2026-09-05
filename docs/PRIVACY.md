# Privacy

ListingLens QC is designed to be fully on-device and to collect nothing.

## What the app does

- Reads the photos you explicitly select via `PhotosUI`'s `PhotosPicker`.
- Analyzes them locally using Apple's `Vision`, `CoreImage`/`ImageIO`, and `Accelerate`
  frameworks, entirely on-device.
- Displays results, warnings, and a recommended order in-app.
- Persists exactly one user preference locally: your chosen appearance
  (System/Light/Dark/Black), via `UserDefaults`.

## What the app does not do

- No networking of any kind. There is no URLSession, no third-party network SDK, and no
  server component. (Audited: `Grep -r "URLSession\|http://\|https://" ListingLensQC/`
  returns no networking call sites — the only `https://` strings in the repository are
  in documentation/comments, not code.)
- No analytics or crash-reporting SDKs.
- No advertising SDKs.
- No accounts, sign-in, or user identifiers.
- No in-app purchases.
- No generative AI — every "explanation" the app shows is templated, localized text
  selected from a fixed set of measurement-driven keys (see `ExplanationEngine`), never
  model-generated prose.
- No marketplace/API integrations (no Etsy/eBay/Amazon/Shopify calls).
- Photos are never written to disk outside of what iOS itself manages for the picker
  session; ListingLens QC does not copy photos into its own persistent storage or export
  them anywhere.

## Data retention

Nothing analyzed by the app is retained once you leave the Results/Recommended Order
flow or start a new audit — `AuditViewModel.reset()` clears all in-memory state. There is
no local database of past audits in this version.

## Privacy manifest

See `Assets/PrivacyInfo.xcprivacy` for the formal Privacy Manifest. It declares:

- **No** tracking domains.
- **No** Required Reason APIs beyond what is strictly necessary. The app uses
  `UserDefaults` only to store the single local appearance preference described above;
  this is declared under reason `CA92.1` ("Access info from same app, per user, on-device
  only, not shared").
- No collected data types are declared, because none are collected.

## Third-party dependencies

None. ListingLensQC uses only first-party Apple frameworks (SwiftUI, PhotosUI, Vision,
CoreImage, ImageIO, Accelerate, CoreGraphics, Foundation).
