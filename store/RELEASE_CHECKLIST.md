# Release Checklist

- [ ] Replace placeholder bundle identifier `com.example.listinglensqc` with the real one.
- [ ] Create/confirm the App Store Connect app record under the real developer account
      (**TODO — no account exists in this session**).
- [ ] Host `docs/PRIVACY.md` content at a real Privacy Policy URL and fill it into
      `store/APP_STORE_METADATA.md`.
- [ ] Complete the App Privacy questionnaire in App Store Connect using
      `store/APP_PRIVACY.md` as the source of truth.
- [ ] Generate an Xcode project from `Package.swift`, wire up the app target, and run
      `swift test` + the full test suite on a real macOS/Xcode environment.
- [ ] Rasterize the app icon from `Assets/AppIcon/icon.svg` using
      `Assets/AppIcon/generate_icons.py` (or the documented manual steps) and add the
      resulting `AppIcon.appiconset` to the app target.
- [ ] Capture the 7 required screenshots per `store/SCREENSHOT_PLAN.md` on real
      simulators/devices.
- [ ] Manual accessibility pass per `docs/ACCESSIBILITY.md`.
- [ ] Archive with a real signing identity; validate; upload.
- [ ] Submit for review with `store/REVIEW_NOTES.md`.

Every unchecked item above requires tooling (Xcode, a developer account, a real device)
that was not available in the cloud session that authored this repository — see
`COMPLETION_REPORT.md` for the full, honest accounting.
