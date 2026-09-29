// swift-tools-version: 6.4

import PackageDescription

let package = Package(
    name: "swift-whatwg-url",
    platforms: [
        .macOS(.v27),
        .iOS(.v27),
        .tvOS(.v27),
        .watchOS(.v27),
        .visionOS(.v27),
    ],
    products: [

        .library(
            name: "WHATWG URL",
            targets: ["WHATWG URL"]
        ),

        .library(
            name: "WHATWG Form URL Encoded",
            targets: ["WHATWG Form URL Encoded"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/swift-atoms/swift-ascii.git", branch: "main"),
        .package(url: "https://github.com/swift-atoms/swift-byte.git", branch: "main"),
        .package(url: "https://github.com/swift-ietf/swift-rfc-4291.git", branch: "main"),
        .package(url: "https://github.com/swift-ietf/swift-rfc-5952.git", branch: "main"),
        .package(url: "https://github.com/swift-ietf/swift-rfc-791.git", branch: "main"),
        .package(
            url: "https://github.com/swift-standards/swift-domain-standard.git",
            branch: "main"
        ),
    ],
    targets: [

        .target(
            name: "WHATWG URL",
            dependencies: [
                .target(name: "WHATWG Form URL Encoded"),
                .product(name: "ASCII", package: "swift-ascii"),
                .product(name: "Byte", package: "swift-byte"),
                .product(name: "Byte", package: "swift-byte"),
                .product(name: "Domain Standard", package: "swift-domain-standard"),
                .product(name: "RFC 4291", package: "swift-rfc-4291"),
                .product(name: "RFC 5952", package: "swift-rfc-5952"),
                .product(name: "RFC 791", package: "swift-rfc-791"),
            ]
        ),

        .target(
            name: "WHATWG Form URL Encoded",
            dependencies: [
                .product(name: "ASCII", package: "swift-ascii"),
                .product(name: "Byte", package: "swift-byte"),
                .product(name: "Byte", package: "swift-byte"),
            ]
        ),

        .testTarget(
            name: "WHATWG Form URL Encoded Tests",
            dependencies: [
                .target(name: "WHATWG Form URL Encoded"),
                .product(name: "ASCII", package: "swift-ascii"),
                .product(name: "Byte", package: "swift-byte"),
                .product(name: "Byte", package: "swift-byte"),
            ]
        ),
        .testTarget(
            name: "WHATWG URL Tests",
            dependencies: [
                .target(name: "WHATWG URL"),
                .product(name: "ASCII", package: "swift-ascii"),
                .product(name: "Byte", package: "swift-byte"),
                .product(name: "Byte", package: "swift-byte"),
                .product(name: "Domain Standard", package: "swift-domain-standard"),
                .product(name: "RFC 4291", package: "swift-rfc-4291"),
                .product(name: "RFC 791", package: "swift-rfc-791"),
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)

for target in package.targets where ![.system, .binary, .plugin, .macro].contains(target.type) {
    let ecosystem: [SwiftSetting] = [
        .strictMemorySafety(),
        .enableUpcomingFeature("ExistentialAny"),
        .enableUpcomingFeature("InternalImportsByDefault"),
        .enableUpcomingFeature("MemberImportVisibility"),
        .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
        .enableExperimentalFeature("Lifetimes"),
    ]

    let package: [SwiftSetting] = []

    target.swiftSettings = (target.swiftSettings ?? []) + ecosystem + package
}
