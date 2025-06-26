// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MyApp",
    products: [
        .library(
            name: "MyApp",
            targets: ["MyApp"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/marcusziade/OpenAIKit.git", from: "1.0.0")
    ],
    targets: [
        .target(
            name: "MyApp"
        )
    ]
)