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
        .target(
            name: "SysmCore",
            dependencies: [
                .product(name: "Yams", package: "Yams"),
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ],
            path: "Sources/SysmCore",
            linkerSettings: [
                .linkedFramework("Photos"),
            ]
        ),
        .executableTarget(
            name: "sysm",
            dependencies: [
                "SysmCore",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ],
            path: "Sources/sysm"
        ),
        .testTarget(
            name: "SysmCoreTests",
            dependencies: ["SysmCore"],
            path: "Tests/SysmCoreTests"
        ),
        .testTarget(
            name: "IntegrationTests",
            dependencies: ["SysmCore"],
            path: "Tests/IntegrationTests"
        ),
    ]
)
