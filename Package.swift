// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "ListingLensQC",
    defaultLocalization: "en",
    platforms: [.iOS(.v17)],
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
