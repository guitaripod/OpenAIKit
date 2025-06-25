// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MyApp",
    dependencies: [
        .package(url: "https://github.com/marcusziade/OpenAIKit.git", from: "1.0.0"),
        // Other dependencies...
    ],
    targets: [
        .target(
            name: "MyApp",
            dependencies: [
                .product(name: "OpenAIKit", package: "OpenAIKit"),
            ]),
    ]
)