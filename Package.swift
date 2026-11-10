// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Postino",
    platforms: [.macOS(.v14)],
    targets: [
        .target(name: "PostinoCore", path: "Sources/PostinoCore"),
        .executableTarget(name: "Postino", dependencies: ["PostinoCore"], path: "Sources/Postino"),
        .testTarget(name: "PostinoCoreTests", dependencies: ["PostinoCore"], path: "Tests/PostinoCoreTests"),
    ]
)
