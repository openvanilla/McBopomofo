// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "CandidateKit",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "CandidateKit",
            targets: ["CandidateKit"]
        ),
        .executable(
            name: "CandidateKitPreview",
            targets: ["CandidateKitPreview"]
        ),
    ],
    targets: [
        .target(
            name: "CandidateKit",
            resources: [.process("Resources")]
        ),
        .executableTarget(
            name: "CandidateKitPreview",
            dependencies: ["CandidateKit"]
        ),
        .testTarget(
            name: "CandidateKitTests",
            dependencies: ["CandidateKit"]
        ),
    ]
)
