import XCTest
@testable import ListingLensQCCore

final class LocalizationTests: XCTestCase {
    func testForbiddenLocalesAreExcludedFromSupportedList() {
        let service = LocalizationService(preferredLocale: "en")
        for forbidden in ["ru", "be", "fa-IR", "fa", "ru-RU", "be-BY"] {
            XCTAssertFalse(service.supportedLocales.contains(forbidden), "\(forbidden) must never be listed as supported")
        }
    }

    func testForbiddenLocaleDetectionIsCaseInsensitiveAndPrefixAware() {
        XCTAssertTrue(ForbiddenLocales.isForbidden("ru"))
        XCTAssertTrue(ForbiddenLocales.isForbidden("RU"))
        XCTAssertTrue(ForbiddenLocales.isForbidden("ru-RU"))
        XCTAssertTrue(ForbiddenLocales.isForbidden("be"))
        XCTAssertTrue(ForbiddenLocales.isForbidden("fa-IR"))
        XCTAssertTrue(ForbiddenLocales.isForbidden("fa"))
        XCTAssertFalse(ForbiddenLocales.isForbidden("en"))
        XCTAssertFalse(ForbiddenLocales.isForbidden("uk"))
    }

    func testForbiddenPreferredLocaleFallsBackToEnglishNeverToAnotherForbiddenLocale() {
        let service = LocalizationService(preferredLocale: "ru-RU")
        XCTAssertEqual(service.activeLocale, "en")
        let service2 = LocalizationService(preferredLocale: "fa-IR")
        XCTAssertEqual(service2.activeLocale, "en")
    }

    func testSettingForbiddenLocaleAtRuntimeIsRejected() {
        let service = LocalizationService(preferredLocale: "en")
        service.setLocale("be")
        XCTAssertEqual(service.activeLocale, "en")
    }

    func testAllFiveLaunchLocalesAreSupportedAndDistinctFromForbidden() {
        let expected = ["en", "uk", "zh-Hans", "ja", "ko"]
        let service = LocalizationService(preferredLocale: "en")
        XCTAssertEqual(Set(service.supportedLocales), Set(expected))
    }

    func testUnknownLocaleFallsBackToEnglishString() {
        let service = LocalizationService(preferredLocale: "en")
        let value = service.string(for: "warning.blurry", locale: "xx-XX")
        XCTAssertEqual(value, LocalizationCatalogs.en["warning.blurry"])
    }

    func testEveryWarningKeyIsTranslatedInEveryLaunchLocale() {
        let keys = WarningKindAllRawValuesForTesting.keys.map { "warning.\($0)" }
        for (locale, catalog) in LocalizationCatalogs.all {
            for key in keys {
                XCTAssertNotNil(catalog[key], "\(locale) is missing translation for \(key)")
            }
        }
    }
}

private enum WarningKindAllRawValuesForTesting {
    static let keys: [String] = [
        "weakResolution", "unusableResolution", "blurry", "underexposed", "overexposed",
        "lowContrast", "poorFraming", "probableDuplicate", "verySimilar",
        "missingFramingSignal", "missingAestheticsSignal"
    ]
}
