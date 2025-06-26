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
    targets: [
        .target(
            name: "MyApp"
        )
    ]
)