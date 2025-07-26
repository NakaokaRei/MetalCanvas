// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MetalCanvas",
    platforms: [
        .macOS(.v14),
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "MetalCanvas",
            targets: ["MetalCanvas"]),
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "MetalCanvas",
            dependencies: []),
        .testTarget(
            name: "MetalCanvasTests",
            dependencies: ["MetalCanvas"]),
    ]
)
