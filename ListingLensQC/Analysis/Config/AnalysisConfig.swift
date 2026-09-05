import Foundation

/// Centralized, deterministic configuration for the entire analysis pipeline.
/// Every threshold, weight and penalty used anywhere in ListingLens QC lives here so
/// the scoring model can be audited, tuned and unit-tested from a single source of truth.
///
/// See docs/SCORING.md for the rationale behind these numbers.
public enum AnalysisConfig {

    // MARK: - Batch limits

    public static let minBatchSize = 1
    public static let maxBatchSize = 20

    /// Maximum number of concurrent decode/analysis tasks (bounded concurrency).
    public static let maxConcurrentAnalysisTasks = 4

    /// Longest edge used for analysis thumbnails, in pixels. Full-resolution images are
    /// never retained for signal extraction — only for the final on-screen detail view.
    public static let analysisThumbnailMaxEdge: CGFloat = 1024

    // MARK: - Resolution thresholds

    public enum Resolution {
        /// Below this min-edge (px) a photo is flagged as weak resolution for e-commerce use.
        public static let weakMinEdgePixels: Int = 1000
        /// Below this min-edge the photo is considered unusable as a primary listing photo.
        public static let unusableMinEdgePixels: Int = 400
        /// Megapixel count considered "excellent" for zoom/crop tolerance.
        public static let excellentMegapixels: Double = 3.0
    }

    // MARK: - Sharpness / blur (variance-of-Laplacian style edge-energy metric)

    public enum Sharpness {
        /// Raw edge-energy scores below this are classified as blurry.
        public static let blurryThreshold: Double = 8.0
        /// Raw edge-energy scores at/above this are classified as sharp.
        public static let sharpThreshold: Double = 30.0
        /// Normalization ceiling: scores at/above this map to normalized 1.0.
        public static let normalizationCeiling: Double = 60.0
    }

    // MARK: - Exposure (histogram-based)

    public enum Exposure {
        /// Fraction of pixels in the bottom 3% luma bins beyond which we flag "crushed shadows".
        public static let crushedShadowFraction: Double = 0.35
        /// Fraction of pixels in the top 3% luma bins beyond which we flag "blown highlights".
        public static let blownHighlightFraction: Double = 0.35
        /// Mean luma below this (0-255) is flagged as underexposed.
        public static let underexposedMeanLuma: Double = 60
        /// Mean luma above this (0-255) is flagged as overexposed.
        public static let overexposedMeanLuma: Double = 200
        /// Ideal mean luma band center used for the exposure quality curve.
        public static let idealMeanLuma: Double = 128
    }

    // MARK: - Contrast

    public enum Contrast {
        /// Standard deviation of luma below this is flagged as low contrast / flat.
        public static let lowContrastStdDev: Double = 30
    }

    // MARK: - Framing / composition (Vision saliency + heuristics)

    public enum Framing {
        /// Minimum fraction of frame area the salient object should occupy.
        public static let minSubjectAreaFraction: Double = 0.08
        /// Maximum fraction — a subject filling almost the whole frame may be too tight.
        public static let maxSubjectAreaFraction: Double = 0.92
        /// Distance (fraction of image diagonal) from the ideal rule-of-thirds points
        /// beyond which composition is scored down.
        public static let centeringTolerance: Double = 0.35
    }

    // MARK: - Similarity / duplicate detection (VNFeaturePrint distance)

    public enum Similarity {
        /// Feature-print distance below this ⇒ "probable duplicate".
        public static let duplicateDistance: Float = 0.15
        /// Feature-print distance below this (and ≥ duplicateDistance) ⇒ "very similar".
        public static let verySimilarDistance: Float = 0.30
        /// Distance at/above this ⇒ "sufficiently distinct".
        public static let distinctDistance: Float = 0.30
    }

    // MARK: - Overall score weights (sum to 1.0). Centralized to avoid double counting.

    public enum Weights {
        public static let resolution: Double = 0.15
        public static let sharpness: Double = 0.30
        public static let exposure: Double = 0.20
        public static let contrast: Double = 0.10
        public static let framing: Double = 0.15
        public static let aesthetics: Double = 0.10

        public static var sum: Double {
            resolution + sharpness + exposure + contrast + framing + aesthetics
        }
    }

    // MARK: - Penalties

    public enum Penalties {
        /// Subtracted from overall score (0-100 scale) when the photo is part of a
        /// probable-duplicate cluster and is not the best member of that cluster.
        public static let duplicateRedundancy: Double = 18
        /// Subtracted when part of a very-similar cluster and not the best member.
        public static let verySimilarRedundancy: Double = 8
        /// Subtracted when resolution is below the "unusable" threshold.
        public static let unusableResolution: Double = 25
    }

    // MARK: - Hero ranking weights (distinct from overall score weights; see docs/SCORING.md)

    public enum HeroWeights {
        public static let overallScore: Double = 0.35
        public static let sharpness: Double = 0.20
        public static let resolution: Double = 0.10
        public static let framing: Double = 0.15
        public static let saliency: Double = 0.10
        public static let aesthetics: Double = 0.10
        public static let redundancyPenalty: Double = 0.20 // applied as subtraction
    }

    // MARK: - Recommended Order (diversity-aware reranking)

    public enum Ranking {
        /// Similarity distance below which two adjacent-ranked photos are considered
        /// "near duplicates" for the consecutive-penalty rule.
        public static let nearDuplicateAdjacencyDistance: Float = 0.30
        /// Score penalty (0-100 scale) applied when placing a photo immediately after
        /// a near-duplicate of it, encouraging spread.
        public static let consecutiveNearDuplicatePenalty: Double = 12
    }
}
