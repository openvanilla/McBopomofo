// swift-tools-version:5.4
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "TooltipUI",
    platforms: [
        .macOS(.v10_15)
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "TooltipUI",
            targets: ["TooltipUI"]
        ),
        .executable(
            name: "TooltipPreview",
            targets: ["TooltipPreview"]
        )
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
    ],
    targets: [
        .target(
            name: "TooltipUI",
            dependencies: []
        ),
        .executableTarget(
            name: "TooltipPreview",
            dependencies: ["TooltipUI"]
        ),
    ]
)
