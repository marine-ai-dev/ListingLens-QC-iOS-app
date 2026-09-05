# Release

## Versioning

- Marketing version: `1.0.0`
- Build number: `1`
- Minimum iOS target: **17.0**
- Bundle identifier: `com.example.listinglensqc` (**TODO/placeholder** — replace with
  the real reverse-DNS identifier tied to the developer's actual App Store Connect team
  before submission).

## Build configuration expectations

- **Debug**: default SwiftUI previews, no fake/seeded data paths are compiled in
  (there is no `#if DEBUG` test-data seeding anywhere in this codebase — verified by
  inspection: `AuditViewModel` only ever populates `inputs` from real `PhotosPickerItem`
  loads).
- **Release**: code signing is expected to be configured with
  `CODE_SIGNING_ALLOWED=NO` / `CODE_SIGN_IDENTITY=""` for CI smoke builds (see
  `.github/workflows/ios-ci.yml`); a real signing identity and provisioning profile must
  be supplied by the developer for an actual App Store archive, which this cloud session
  has no access to and does not attempt to fabricate.

## Steps for a future maintainer with Xcode access

1. Open `Package.swift` in Xcode 16+, or run
   `swift package generate-xcodeproj` to produce a `.xcodeproj`.
2. Create (or confirm) an iOS App target that depends on `ListingLensQCUI`, set its
   bundle identifier, deployment target (17.0), and add `Assets/PrivacyInfo.xcprivacy`
   and the rasterized `AppIcon.appiconset` to that target.
3. Run the full test suite (`swift test`, plus the app target's unit/UI test bundles).
4. Run the XCUITest screenshot scaffolding on required device classes.
5. Archive with a real signing identity, validate, and upload via Xcode Organizer or
   `xcodebuild -exportArchive`.
6. Fill in the placeholders in `store/APP_STORE_METADATA.md` and
   `store/RELEASE_CHECKLIST.md` with real account/URL details before submitting.

## What this repository does NOT include (by design)

- No `.xcodeproj`/`.xcworkspace` is committed — Xcode-generated project files are
  environment-specific and this repository was authored without Xcode available. The
  Swift Package (`Package.swift`) is the source of truth for targets and dependencies.
- No provisioning profiles, signing certificates, or App Store Connect API keys.
