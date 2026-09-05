# App Privacy (App Store Connect questionnaire draft)

Answers to map directly onto Apple's App Privacy questionnaire in App Store Connect.

## Data Collection

**Does this app collect data?** No.

All analysis is performed on-device. No data of any kind (photos, derived measurements,
identifiers, usage, diagnostics) is collected, transmitted, or linked to the user.

## Data linked to you / not linked to you

Not applicable — no data is collected.

## Tracking

This app does not track users, and does not use the Advertising Identifier (IDFA) or
any cross-app/cross-site tracking technique.

## Required Reason API usage

Declared in `Assets/PrivacyInfo.xcprivacy`:

- `NSPrivacyAccessedAPICategoryUserDefaults` — reason `CA92.1` (local, on-device,
  per-user preference storage: the chosen appearance mode; not shared with any other
  app or server).

No other Required Reason APIs are used.

## Placeholders

- **TODO**: App Store Connect "Contact Information" and "Copyright" fields — not
  fabricated here; must be filled in by the real developer account owner.
