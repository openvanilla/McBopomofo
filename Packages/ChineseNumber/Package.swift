// swift-tools-version: 5.4
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ChineseNumber",
    products: [
        .library(
            name: "ChineseNumber",
            targets: ["ChineseNumber"]),
    ],
    targets: [
        .target(
            name: "ChineseNumber"),
    ]
)
