// swift-tools-version: 6.0
//
// SwiftPM test harness for core math (run: `swift test`)
// This does not affect the iOS app target; it exists to keep analytics logic testable in CI.

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
