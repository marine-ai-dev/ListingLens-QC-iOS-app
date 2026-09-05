# Contributing

Thanks for your interest in ListingLens QC.

## Ground rules

- **No networking, ever.** This app's entire value proposition is on-device privacy.
  Any PR that introduces a network call, analytics SDK, or third-party tracker will be
  rejected.
- **No real/copyrighted photos in the repository**, including in tests. All test
  fixtures must be synthetically generated in code — see
  `Tests/ListingLensQCTests/Fixtures/SyntheticImageFactory.swift`.
- **`ru`, `be`, and `fa`/`fa-IR` must never be added** to the localization registry,
  picker, or fallback logic. See `docs/LOCALIZATION.md` for the rationale and the
  regression tests that enforce this.
- **Centralize constants.** Any new threshold, weight, or penalty for the analysis
  pipeline belongs in `AnalysisConfig`, not scattered inline — and must be documented in
  `docs/SCORING.md`.
- **Views stay thin.** SwiftUI screens under `ListingLensQC/Screens` must not contain
  scoring/ranking/similarity business logic — that belongs in `ListingLensQCCore`.

## Workflow

1. Fork/branch from `main` (or the active feature branch).
2. Write tests first where practical — the project favors deterministic, synthetic-data
   unit tests over UI-driven ones for anything in `ListingLensQCCore`.
3. Run `swift test` locally before opening a PR.
4. Keep commits focused and descriptive.

## Code style

- Prefer value types (`struct`/`enum`) and `Sendable` conformance for anything crossing
  a concurrency boundary.
- Prefer `actor` for stateful services that coordinate concurrent work (see
  `AnalysisPipeline`).
- Document any non-obvious threshold or heuristic with a doc comment explaining *why*,
  not just *what*.
