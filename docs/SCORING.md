# Scoring Model

This document is the authoritative reference for every formula, weight, threshold, and
penalty used by ListingLens QC. All of these constants live in exactly one file,
`ListingLensQC/Analysis/Config/AnalysisConfig.swift`, so this document and the code
should never drift — if you change a number, change it there and update this file.

## Pipeline

```
PhotoInput -> Decoding -> SignalExtraction -> Normalization -> Similarity -> Scoring -> HeroScoring -> Ranking -> Explanations -> UI
```

Each stage is a pure/deterministic value type or a `Sendable` service with no UI
dependency, so every stage is independently unit-testable (see `Tests/ListingLensQCTests`).

## Raw signals

| Signal | Extractor | Method |
|---|---|---|
| Resolution | `PixelSize` (from ImageIO metadata) | width/height/min-edge/pixel count, no full decode required |
| Sharpness | `SharpnessExtractor` | RMS of a 3×3 discrete Laplacian over luma ("edge energy") |
| Exposure | `ExposureExtractor` | Luma histogram: mean, std-dev, crushed-shadow / blown-highlight fraction |
| Contrast | `ExposureExtractor` | Luma standard deviation |
| Framing | `FramingExtractor` | Vision attention-based saliency bounding box + rule-of-thirds distance |
| Aesthetics | `AestheticsExtractor` | `VNCalculateImageAestheticsScoresRequest` (iOS 18+), one weighted input among many |

Any signal that cannot be computed (Vision failure, image too small, API unavailable) is
recorded as `nil`, never as a fabricated default. See "Missing signal policy" below.

## Normalization (0...1)

- **Resolution**: `0.6 * min(1, minEdge / weakMinEdgePixels) + 0.4 * min(1, megapixels / 3.0)`, clamped to `[0,1]`; `0` if at/below the "unusable" min-edge (400px).
- **Sharpness**: `min(1, edgeEnergy / 60.0)`.
- **Exposure**: `max(0, 1 - |meanLuma - 128| / 128)`, multiplied by `0.4` if crushed-shadow or blown-highlight fraction exceeds 35%.
- **Contrast**: `min(1, stdDev / 80.0)`.
- **Framing**: `0.5 * areaScore + 0.5 * centerScore`, where `areaScore` penalizes a salient subject occupying less than 8% or more than 92% of the frame, and `centerScore = 1 - normalizedDistanceFromNearestRuleOfThirdsPoint`.
- **Aesthetics**: Vision's `overallScore` (≈ -1...1) remapped to 0...1.

## Overall score (0-100)

```
overall = 100 * (Σ weight_i * normalized_i) / (Σ weight_i for available signals) - penalties
```

Weights (sum to 1.0 when every signal is available):

| Signal | Weight |
|---|---|
| Sharpness | 0.30 |
| Exposure | 0.20 |
| Resolution | 0.15 |
| Framing | 0.15 |
| Contrast | 0.10 |
| Aesthetics | 0.10 |

**Missing signal policy**: weight is *not* redistributed by inflating other weights;
instead, the weighted average is computed only over available signals (dividing by the
sum of their weights). If literally no signal could be measured, the score is a fixed,
clearly-neutral 50 rather than 0 or 100 — neither a false failure nor a false pass.

Penalties (subtracted from the weighted base score):

| Condition | Penalty |
|---|---|
| Min-edge ≤ 400px ("unusable resolution") | -25 |
| Non-best member of a probable-duplicate cluster | -18 |
| Non-best member of a very-similar cluster | -8 |

Final score is clamped to `[0, 100]`.

## Similarity / duplicate detection

Pairwise `VNFeaturePrintObservation` distance (`computeDistance`) between every pair of
photos in the batch (bounded to 20 photos ⇒ ≤190 comparisons):

| Distance | Classification |
|---|---|
| < 0.15 | Probable duplicate |
| 0.15 – 0.30 | Very similar |
| ≥ 0.30 | Sufficiently distinct |

Photos are grouped into clusters via union-find over non-distinct edges (transitive:
if A~B and B~C, all three cluster together even if A and C were never compared as
similar directly). Similarity is *never* used to auto-delete anything — only to warn
and to inform hero/ranking penalties.

## Best Hero Candidate

A **separate** weighted model from the overall score — deliberately not `max(overall)`
— so a technically-highest-scoring photo that is a near-duplicate of another photo does
not automatically win:

| Component | Weight |
|---|---|
| Overall score (0-100, scaled to 0-1) | 0.35 |
| Sharpness (normalized) | 0.20 |
| Framing (normalized) | 0.15 |
| Resolution (normalized) | 0.10 |
| Saliency availability | 0.10 |
| Aesthetics (normalized) | 0.10 |
| Redundancy penalty (subtracted) | up to -0.20 |

Redundancy penalty is `1.0` for a non-best duplicate member, `0.5` for a non-best
very-similar member, `0` otherwise.

**Guarantee**: `HeroScoringEngine.selectHero` always returns exactly one candidate for
any non-empty batch. Ties are broken deterministically by ascending `PhotoID` UUID
string, so re-running an identical batch always names the same hero.

## Recommended Order

A greedy, diversity-aware rerank, not a plain sort by score:

1. Base order: overall score descending, PhotoID ascending (deterministic tiebreak).
2. The hero, if one exists, is always placed first.
3. At each subsequent step, the remaining candidate with the highest *effective* score
   is placed next, where effective score = overall score, minus 12 points if it would
   land immediately after a photo it is a near-duplicate of (feature-print distance
   < 0.30).

**Determinism guarantee**: identical `scores` + identical `similarityPairs` +
identical `AnalysisConfig` always produces identical output order. This is exercised by
`HeroAndRankingTests.testRecommendedOrderIsDeterministicAcrossRuns` and the 20-image
stress harness in `StressHarnessTests`.

## Limitations

- Sharpness, exposure and framing measurements are statistical approximations, not a
  semantic understanding of the product photographed — copy in the app is deliberately
  worded as measurement-grounded ("looks less sharp than the rest of this batch"), never
  as a claim about what the photo depicts.
- Vision's saliency and aesthetics models were trained on general photography, not
  specifically on e-commerce product photos; treat their contribution as one weighted
  input, not a verdict.
- The exact numeric thresholds above are heuristics tuned by inspection, not by a
  labeled dataset (there is no networking or telemetry to collect one). They are
  documented and centralized specifically so they can be revisited.
