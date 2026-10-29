// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftUI2",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
        .tvOS(.v17),
        .watchOS(.v10),
        .visionOS(.v1)
    ],
    products: [
        .library(
            name: "SwiftUI2",
            targets: ["SwiftUI2Core", "SwiftUI2AppleModels", "SwiftUI2SwiftUI"]
        ),
        .library(
            name: "SwiftUI2Core",
            targets: ["SwiftUI2Core"]
        ),
        .library(
            name: "SwiftUI2AppleModels",
            targets: ["SwiftUI2AppleModels"]
        ),
        .library(
            name: "SwiftUI2SwiftUI",
            targets: ["SwiftUI2SwiftUI"]
        ),
        .library(
            name: "SwiftUI2Testing",
            targets: ["SwiftUI2Testing"]
        )
    ],
    targets: [
        // Core framework abstractions & engine - platform independent
        .target(
            name: "SwiftUI2Core",
            dependencies: [],
            path: "Sources/SwiftUI2Core"
        ),
        // Apple Foundation Models adapter
        .target(
            name: "SwiftUI2AppleModels",
            dependencies: ["SwiftUI2Core"],
            path: "Sources/SwiftUI2AppleModels"
        ),
        // SwiftUI integration layer
        .target(
            name: "SwiftUI2SwiftUI",
            dependencies: ["SwiftUI2Core"],
            path: "Sources/SwiftUI2SwiftUI"
        ),
        // Deterministic testing utilities & mocks
        .target(
            name: "SwiftUI2Testing",
            dependencies: ["SwiftUI2Core"],
            path: "Sources/SwiftUI2Testing"
        ),
        // Unit tests for SwiftUI2Core
        .testTarget(
            name: "CoreTests",
            dependencies: ["SwiftUI2Core", "SwiftUI2Testing"],
            path: "Tests/CoreTests"
        ),
        // Tests for Apple Foundation Models adapter logic
        .testTarget(
            name: "AppleModelTests",
            dependencies: ["SwiftUI2AppleModels", "SwiftUI2Testing"],
            path: "Tests/AppleModelTests"
        ),
        // Tests for SwiftUI integration
        .testTarget(
            name: "SwiftUITests",
            dependencies: ["SwiftUI2SwiftUI", "SwiftUI2Testing"],
            path: "Tests/SwiftUITests"
        ),
        // Integration tests
        .testTarget(
            name: "IntegrationTests",
            dependencies: ["SwiftUI2Core", "SwiftUI2AppleModels", "SwiftUI2SwiftUI", "SwiftUI2Testing"],
            path: "Tests/IntegrationTests"
        )
    ]
)
