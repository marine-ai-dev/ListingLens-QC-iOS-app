# App Review Notes (draft)

ListingLens QC is a fully offline, on-device photo quality checker aimed at online
sellers. There is no account system to test — the app is usable immediately after photo
library permission is granted.

## How to test

1. Launch the app.
2. Tap "Select Photos" and choose between 1 and 20 photos from the library (any
   photos — the app does not require product photos specifically to demonstrate its
   analysis flow).
3. Wait for on-device analysis to complete (no network activity occurs; this can be
   confirmed with any network proxy/monitor).
4. Review the per-photo scores, the "Best Hero Candidate" card, and Recommended Order.
5. Tap into any photo for its detailed strengths/warnings.
6. Tap "Start New Audit" to reset and try another batch.

## Permissions requested

- **Photo Library** (via `PhotosPicker`, the modern PhotosUI picker, which does not
  require full library access — only the photos the user explicitly selects are ever
  handed to the app).

## Notes for the reviewer

- No login, no purchases, no ads, no external links required to use core functionality.
- No server-side component exists; there is nothing to demo remotely.
- **TODO (placeholder)**: demo account credentials — not applicable, no accounts exist.
