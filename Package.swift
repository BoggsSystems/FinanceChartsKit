// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "FinanceChartsKit",
    platforms: [
        .tvOS(.v17),
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "FinanceChartsKit",
            targets: ["FinanceChartsKit"]),
        .executable(
            name: "AppDemo",
            targets: ["AppDemo"])
    ],
    dependencies: [],
    targets: [
        .target(
            name: "FinanceChartsKit",
            dependencies: [],
            resources: [
                .process("Resources")
            ]
        ),
        .executableTarget(
            name: "AppDemo",
            dependencies: ["FinanceChartsKit"],
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "FinanceChartsKitTests",
            dependencies: ["FinanceChartsKit"],
            resources: [
                .process("Resources")
            ]
        ),
    ]
)