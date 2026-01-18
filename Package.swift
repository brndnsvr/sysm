// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "sysm",
    platforms: [
        .macOS(.v13)
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.3.0"),
        .package(url: "https://github.com/jpsim/Yams.git", from: "5.0.0"),
        .package(url: "https://github.com/apple/swift-docc-plugin.git", from: "1.3.0"),
    ],
    targets: [
        .executableTarget(
            name: "sysm",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "Yams", package: "Yams"),
            ],
            path: "Sources/sysm",
            linkerSettings: [
                .linkedFramework("Photos"),
            ]
        ),
        .testTarget(
            name: "sysmTests",
            dependencies: [],
            path: "Tests/sysmTests"
        ),
    ]
)
