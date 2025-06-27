// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "OpenAIKit",
    platforms: [
        .iOS(.v15),
        .macOS(.v13),
        .watchOS(.v8),
        .tvOS(.v15),
        .visionOS(.v1)
    ],
    products: [
        .library(
            name: "OpenAIKit",
            targets: ["OpenAIKit"]),
        .executable(
            name: "OpenAIKitTester",
            targets: ["OpenAIKitTester"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.0.0"),
    ],
    targets: [
        .target(
            name: "OpenAIKit",
            dependencies: [],
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
        .executableTarget(
            name: "OpenAIKitTester",
            dependencies: ["OpenAIKit"],
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "OpenAIKitTests",
            dependencies: ["OpenAIKit"]),
    ]
)
