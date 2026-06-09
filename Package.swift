// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "wealthbox-swift",
    platforms: [
        .macOS("14.0")
    ],
    products: [
        .library(name: "Wealthbox", targets: ["Wealthbox"]),
        .executable(name: "wealthbox", targets: ["WealthboxCLI"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.8.2")
    ],
    targets: [
        .target(name: "Wealthbox"),
        .executableTarget(
            name: "WealthboxCLI",
            dependencies: [
                "Wealthbox",
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ]
        ),
        .testTarget(
            name: "WealthboxTests",
            dependencies: ["Wealthbox"]
        )
    ]
)
