// swift-tools-version: 6.0
//
// Core analytics library for the FairwayIQ app (run tests with `swift test`).
// The iOS app target links this package; it is the single source of truth
// for analytics math.

import PackageDescription

let package = Package(
    name: "FairwayIQCore",
    platforms: [
        .macOS(.v14),
        .iOS("26.2")
    ],
    products: [
        .library(name: "FairwayIQCore", targets: ["FairwayIQCore"])
    ],
    targets: [
        .target(
            name: "FairwayIQCore",
            path: "Sources/FairwayIQCore"
        ),
        .testTarget(
            name: "FairwayIQCoreTests",
            dependencies: ["FairwayIQCore"],
            path: "Tests/FairwayIQCoreTests"
        )
    ]
)
