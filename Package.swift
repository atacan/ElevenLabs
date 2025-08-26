// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ElevenLabs",
    platforms: [.macOS(.v14), .iOS(.v17), .tvOS(.v17)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "ElevenLabs",
            targets: ["ElevenLabs"]
        ),
        .library(
            name: "ElevenLabsTypes",
            targets: ["ElevenLabsTypes"]
        ),
        .library(
            name: "ElevenLabsUrlSessionClient",
            targets: ["ElevenLabsUrlSessionClient"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-openapi-generator", from: "1.10.2"),
        .package(url: "https://github.com/apple/swift-openapi-runtime", from: "1.8.2"),
        .package(url: "https://github.com/swift-server/swift-openapi-async-http-client", from: "1.1.0"),
        .package(url: "https://github.com/apple/swift-openapi-urlsession", from: "1.1.0"),
        .package(url: "https://github.com/atacan/UsefulThings", branch: "main"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "ElevenLabs",
            dependencies: [
                .product(name: "OpenAPIRuntime", package: "swift-openapi-runtime"),
                .product(name: "OpenAPIAsyncHTTPClient", package: "swift-openapi-async-http-client"),
                .target(name: "ElevenLabsTypes"),
            ]
        ),
        .testTarget(
            name: "ElevenLabsTests",
            dependencies: ["ElevenLabs", .product(name: "UsefulThings", package: "UsefulThings")]
        ),
        .target(
            name: "ElevenLabsTypes",
            dependencies: [
                .product(name: "OpenAPIRuntime", package: "swift-openapi-runtime")
            ]
        ),
        .target(
            name: "ElevenLabsUrlSessionClient",
            dependencies: [
                .product(name: "OpenAPIRuntime", package: "swift-openapi-runtime"),
                .product(name: "OpenAPIURLSession", package: "swift-openapi-urlsession"),
                .target(name: "ElevenLabsTypes"),
            ]
        ),
    ]
)
