// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "ListingLensQC",
    defaultLocalization: "en",
    // .macOS is declared alongside .iOS so `swift build`/`swift test` on a macOS CI
    // runner's host toolchain resolve SwiftUI/Vision availability against a modern
    // macOS deployment target instead of an ancient implicit default. The shipping
    // app itself only ever targets iOS 17+ (see docs/RELEASE.md); this package also
    // builds for macOS purely so its logic can be exercised by `swift test` in CI
    // without requiring a full Xcode project + booted iOS Simulator.
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "ListingLensQCCore", targets: ["ListingLensQCCore"]),
        .library(name: "ListingLensQCUI", targets: ["ListingLensQCUI"])
    ],
    targets: [
        .target(
            name: "ListingLensQCCore",
            path: "ListingLensQC",
            sources: ["Analysis", "Localization", "DesignSystem"]
        ),
        .target(
            name: "ListingLensQCUI",
            dependencies: ["ListingLensQCCore"],
            path: "ListingLensQC",
            sources: ["Screens", "App"]
        ),
        .testTarget(
            name: "ListingLensQCTests",
            dependencies: ["ListingLensQCCore"],
            path: "Tests/ListingLensQCTests"
        )
    ]
)
