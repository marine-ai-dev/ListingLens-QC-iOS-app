import Foundation

/// In-memory string catalogs for the five launch locales. Real (not placeholder)
/// translations for every key used by the analysis/UI layers referenced in this codebase.
/// `ru`, `be`, and `fa`/`fa-IR` are intentionally absent — see ForbiddenLocales.
enum LocalizationCatalogs {
    static let all: [String: [String: String]] = [
        "en": en,
        "uk": uk,
        "zh-Hans": zhHans,
        "ja": ja,
        "ko": ko
    ]

    static let en: [String: String] = [
        "app.name": "ListingLens QC",
        "strength.resolution.high": "High resolution, ready for zoom and crop.",
        "strength.sharpness.high": "Sharp focus throughout the frame.",
        "strength.exposure.good": "Balanced exposure.",
        "strength.framing.good": "Subject is well framed.",
        "warning.weakResolution": "Resolution is lower than recommended for a primary listing photo.",
        "warning.unusableResolution": "Resolution is too low for reliable use as a listing photo.",
        "warning.blurry": "This photo looks less sharp than the rest of the batch.",
        "warning.underexposed": "This photo looks noticeably dark.",
        "warning.overexposed": "This photo looks noticeably bright, detail may be lost.",
        "warning.lowContrast": "Contrast looks flat compared to the rest of the batch.",
        "warning.poorFraming": "The main subject may be off-center or too small in the frame.",
        "warning.probableDuplicate": "This looks like a near-duplicate of another photo in this batch.",
        "warning.verySimilar": "This looks very similar to another photo in this batch.",
        "warning.missingFramingSignal": "Framing could not be measured for this photo.",
        "warning.missingAestheticsSignal": "An aesthetics signal could not be measured for this photo.",
        "hero.reason.highOverall": "It scores highly across the board.",
        "hero.reason.sharp": "It is one of the sharpest photos in this batch.",
        "hero.reason.resolution": "It has excellent resolution.",
        "hero.reason.framing": "The subject is well framed.",
        "hero.reason.distinct": "It stands apart from other photos rather than duplicating one.",
        "hero.reason.bestAvailable": "It is the strongest option available in this batch."
    ]

    static let uk: [String: String] = [
        "app.name": "ListingLens QC",
        "strength.resolution.high": "Висока роздільна здатність, підходить для масштабування та обрізки.",
        "strength.sharpness.high": "Чітка різкість по всьому кадру.",
        "strength.exposure.good": "Збалансована експозиція.",
        "strength.framing.good": "Об'єкт добре скомпонований у кадрі.",
        "warning.weakResolution": "Роздільна здатність нижча за рекомендовану для основного фото товару.",
        "warning.unusableResolution": "Роздільна здатність надто низька для надійного використання.",
        "warning.blurry": "Це фото виглядає менш чітким, ніж інші у цій серії.",
        "warning.underexposed": "Це фото виглядає помітно темним.",
        "warning.overexposed": "Це фото виглядає помітно яскравим, деталі можуть бути втрачені.",
        "warning.lowContrast": "Контраст виглядає слабким порівняно з іншими фото серії.",
        "warning.poorFraming": "Основний об'єкт може бути зміщений або замалий у кадрі.",
        "warning.probableDuplicate": "Схоже на майже точний дублікат іншого фото в цій серії.",
        "warning.verySimilar": "Дуже схоже на інше фото в цій серії.",
        "warning.missingFramingSignal": "Не вдалося виміряти композицію для цього фото.",
        "warning.missingAestheticsSignal": "Не вдалося виміряти естетичну оцінку для цього фото.",
        "hero.reason.highOverall": "Має високі показники за всіма критеріями.",
        "hero.reason.sharp": "Одне з найчіткіших фото в цій серії.",
        "hero.reason.resolution": "Має відмінну роздільну здатність.",
        "hero.reason.framing": "Об'єкт добре скомпонований.",
        "hero.reason.distinct": "Вирізняється серед інших фото, а не дублює їх.",
        "hero.reason.bestAvailable": "Найкращий доступний варіант у цій серії."
    ]

    static let zhHans: [String: String] = [
        "app.name": "ListingLens QC",
        "strength.resolution.high": "分辨率高，适合缩放和裁剪。",
        "strength.sharpness.high": "整幅画面对焦清晰。",
        "strength.exposure.good": "曝光均衡。",
        "strength.framing.good": "主体构图良好。",
        "warning.weakResolution": "分辨率低于建议的主图标准。",
        "warning.unusableResolution": "分辨率过低，无法可靠地用作商品图片。",
        "warning.blurry": "这张照片看起来不如本组其他照片清晰。",
        "warning.underexposed": "这张照片明显偏暗。",
        "warning.overexposed": "这张照片明显偏亮，细节可能丢失。",
        "warning.lowContrast": "与本组其他照片相比，对比度偏低。",
        "warning.poorFraming": "主体可能偏离中心或在画面中过小。",
        "warning.probableDuplicate": "这张照片看起来与本组中的另一张几乎重复。",
        "warning.verySimilar": "这张照片与本组中的另一张非常相似。",
        "warning.missingFramingSignal": "无法测量此照片的构图。",
        "warning.missingAestheticsSignal": "无法测量此照片的美学评分。",
        "hero.reason.highOverall": "各方面得分都很高。",
        "hero.reason.sharp": "是本组中最清晰的照片之一。",
        "hero.reason.resolution": "分辨率非常出色。",
        "hero.reason.framing": "主体构图良好。",
        "hero.reason.distinct": "与其他照片明显不同，而非重复。",
        "hero.reason.bestAvailable": "是本组中最佳的可用选项。"
    ]

    static let ja: [String: String] = [
        "app.name": "ListingLens QC",
        "strength.resolution.high": "解像度が高く、ズームやトリミングに適しています。",
        "strength.sharpness.high": "画面全体にわたりピントが鮮明です。",
        "strength.exposure.good": "露出のバランスが良好です。",
        "strength.framing.good": "被写体の構図が良好です。",
        "warning.weakResolution": "メイン写真として推奨される解像度を下回っています。",
        "warning.unusableResolution": "解像度が低すぎて、出品写真として使用するには不十分です。",
        "warning.blurry": "この写真は他の写真より鮮明さに欠けるようです。",
        "warning.underexposed": "この写真は明らかに暗く見えます。",
        "warning.overexposed": "この写真は明らかに明るく、ディテールが失われている可能性があります。",
        "warning.lowContrast": "他の写真と比べてコントラストが低いようです。",
        "warning.poorFraming": "被写体が中心からずれているか、画面内で小さすぎる可能性があります。",
        "warning.probableDuplicate": "このセット内の別の写真とほぼ重複しているようです。",
        "warning.verySimilar": "このセット内の別の写真と非常に似ています。",
        "warning.missingFramingSignal": "この写真の構図を測定できませんでした。",
        "warning.missingAestheticsSignal": "この写真の美的スコアを測定できませんでした。",
        "hero.reason.highOverall": "全体的に高いスコアです。",
        "hero.reason.sharp": "このセットの中で最も鮮明な写真の一つです。",
        "hero.reason.resolution": "解像度が非常に優れています。",
        "hero.reason.framing": "被写体の構図が良好です。",
        "hero.reason.distinct": "他の写真を複製せず、独自性があります。",
        "hero.reason.bestAvailable": "このセットの中で最も優れた選択肢です。"
    ]

    static let ko: [String: String] = [
        "app.name": "ListingLens QC",
        "strength.resolution.high": "해상도가 높아 확대 및 자르기에 적합합니다.",
        "strength.sharpness.high": "화면 전체에 걸쳐 선명한 초점을 유지합니다.",
        "strength.exposure.good": "노출이 균형 잡혀 있습니다.",
        "strength.framing.good": "피사체 구도가 잘 잡혀 있습니다.",
        "warning.weakResolution": "기본 상품 사진에 권장되는 해상도보다 낮습니다.",
        "warning.unusableResolution": "해상도가 너무 낮아 상품 사진으로 사용하기 어렵습니다.",
        "warning.blurry": "이 사진은 세트 내 다른 사진보다 선명도가 낮아 보입니다.",
        "warning.underexposed": "이 사진은 눈에 띄게 어둡습니다.",
        "warning.overexposed": "이 사진은 눈에 띄게 밝아 디테일이 손실되었을 수 있습니다.",
        "warning.lowContrast": "세트 내 다른 사진에 비해 대비가 낮아 보입니다.",
        "warning.poorFraming": "피사체가 중앙에서 벗어났거나 화면에서 너무 작을 수 있습니다.",
        "warning.probableDuplicate": "이 세트의 다른 사진과 거의 중복되어 보입니다.",
        "warning.verySimilar": "이 세트의 다른 사진과 매우 유사합니다.",
        "warning.missingFramingSignal": "이 사진의 구도를 측정할 수 없습니다.",
        "warning.missingAestheticsSignal": "이 사진의 미적 점수를 측정할 수 없습니다.",
        "hero.reason.highOverall": "전반적으로 높은 점수를 기록합니다.",
        "hero.reason.sharp": "이 세트에서 가장 선명한 사진 중 하나입니다.",
        "hero.reason.resolution": "해상도가 매우 우수합니다.",
        "hero.reason.framing": "피사체 구도가 잘 잡혀 있습니다.",
        "hero.reason.distinct": "다른 사진을 복제하지 않고 독자적입니다.",
        "hero.reason.bestAvailable": "이 세트에서 가장 우수한 선택입니다."
    ]
}
