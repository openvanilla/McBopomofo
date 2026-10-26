// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SystemCharacterInfo",
    platforms: [.macOS(.v13)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "SystemCharacterInfo",
            targets: ["SystemCharacterInfo"]),
    ],
    dependencies: [
        // SQLite.swift – A type-safe SQLite wrapper for Swift
        .package(url: "https://github.com/stephencelis/SQLite.swift.git", from: "0.17.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "SystemCharacterInfo",
            dependencies: [
                .product(name: "SQLite", package: "SQLite.swift")
            ]
        ),
        .testTarget(
            name: "SystemCharacterInfoTests",
            dependencies: ["SystemCharacterInfo"]
        ),
    ]
)
