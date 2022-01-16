// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "OpenCCBridge",
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "OpenCCBridge",
            targets: ["OpenCCBridge"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        .package(name: "SwiftyOpenCC", url: "https://github.com/ddddxxx/SwiftyOpenCC.git", from: "2.0.0-beta")
        
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "OpenCCBridge",
            dependencies: [
                .product(name: "OpenCC", package: "SwiftyOpenCC")
            ]),
        .testTarget(
            name: "OpenCCBridgeTests",
            dependencies: ["OpenCCBridge"]),
    ]
)
