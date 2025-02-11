// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ElevenLabs",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15),
        .watchOS(.v6),
        .tvOS(.v13),
        .visionOS(.v1),
    ],
    products: [
        .library(
            name: "ElevenLabs",
            targets: ["ElevenLabs"]),
        .library(
            name: "ElevenLabs_AHC",
            targets: ["ElevenLabs_AHC"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-openapi-generator", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-openapi-runtime", from: "1.0.0"),
        .package(
            url: "https://github.com/swift-server/swift-openapi-async-http-client", from: "1.0.0"),
    ],
    targets: [
        .target(
            name: "ElevenLabs"),
        .testTarget(
            name: "ElevenLabsTests",
            dependencies: ["ElevenLabs"]
        ),
        .target(
            name: "ElevenLabs_AHC",
            dependencies: [
                .product(name: "OpenAPIRuntime", package: "swift-openapi-runtime"),
                .product(
                    name: "OpenAPIAsyncHTTPClient", package: "swift-openapi-async-http-client"),
            ]),
        .executableTarget(name: "Prepare"),
        .testTarget(
            name: "ElevenLabs_AHCTests",
            dependencies: ["ElevenLabs_AHC"],
            resources: [
                .copy("Resources")
            ]
        ),
    ]
)
