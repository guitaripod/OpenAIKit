// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "OpenAIKit",
    platforms: [
        .iOS(.v15),
        .macOS(.v13),
        .watchOS(.v8),
        .tvOS(.v15),
        .visionOS(.v1),
        // Note: Linux is supported but doesn't need to be listed here
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
            dependencies: []
        ),
        .executableTarget(
            name: "OpenAIKitTester",
            dependencies: ["OpenAIKit"]
        ),
        .testTarget(
            name: "OpenAIKitTests",
            dependencies: ["OpenAIKit"]),
    ]
)
