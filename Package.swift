// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "wealthbox-swift",
    platforms: [
        .macOS("14.0"),
        .iOS("17.0"),
        .macCatalyst("17.0")
    ],
    products: [
        .library(name: "Wealthbox", targets: ["Wealthbox"]),
        .library(name: "WealthboxQA", targets: ["WealthboxQA"]),
        .executable(name: "wealthbox", targets: ["WealthboxCLI"]),
        .executable(name: "wealthbox-qa", targets: ["WealthboxQACLI"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.8.2")
    ],
    targets: [
        .target(name: "Wealthbox"),
        .target(
            name: "WealthboxQA",
            dependencies: ["Wealthbox"]
        ),
        .executableTarget(
            name: "WealthboxCLI",
            dependencies: [
                "Wealthbox",
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ]
        ),
        .executableTarget(
            name: "WealthboxQACLI",
            dependencies: [
                "Wealthbox",
                "WealthboxQA",
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ]
        ),
        .testTarget(
            name: "WealthboxTests",
            dependencies: ["Wealthbox"]
        ),
        .testTarget(
            name: "WealthboxQAHarnessTests",
            dependencies: ["Wealthbox", "WealthboxQA"]
        ),
        // Tier-2 QA-workspace integration tests. Live-gated: every test
        // is skipped unless WEALTHBOX_QA_ACCESS_TOKEN is supplied at
        // call time (bin/wb-qa-run), so `swift test` in CI never makes
        // a network call from this target.
        .testTarget(
            name: "WealthboxQAIntegrationTests",
            dependencies: ["Wealthbox", "WealthboxQA"]
        )
    ]
)
