// swift-tools-version: 6.2

import PackageDescription

extension String {
    static let whatwgURL: Self = "WHATWG URL"
    static let whatwgFormURLEncoded: Self = "WHATWG Form URL Encoded"
}

extension Target.Dependency {
    static var whatwgURL: Self { .target(name: .whatwgURL) }
    static var whatwgFormURLEncoded: Self { .target(name: .whatwgFormURLEncoded) }
    static var rfc3987: Self { .product(name: "RFC 3987", package: "swift-rfc-3987") }
    static var rfc791: Self { .product(name: "RFC 791", package: "swift-rfc-791") }
    static var rfc5952: Self { .product(name: "RFC 5952", package: "swift-rfc-5952") }
    static var domainStandard: Self { .product(name: "Domain Standard", package: "swift-domain-standard") }
    static var rfc4648: Self { .product(name: "RFC 4648", package: "swift-rfc-4648") }
    static var incits41986: Self { .product(name: "ASCII", package: "swift-ascii") }
    static var binary: Self { .product(name: "Binary Primitives", package: "swift-binary-primitives") }
}

let package = Package(
    name: "swift-whatwg-url",
    platforms: [
        .macOS(.v26),
        .iOS(.v26),
        .tvOS(.v26),
        .watchOS(.v26)
    ],
    products: [
        // Main URL standard
        .library(
            name: "WHATWG URL",
            targets: ["WHATWG URL"]
        ),
        // Form URL encoding (application/x-www-form-urlencoded)
        .library(
            name: "WHATWG Form URL Encoded",
            targets: ["WHATWG Form URL Encoded"]
        )
    ],
    dependencies: [
        .package(path: "../../swift-ietf/swift-rfc-3987"),
        .package(path: "../../swift-ietf/swift-rfc-791"),
        .package(path: "../../swift-ietf/swift-rfc-5952"),
        .package(path: "../../swift-standards/swift-domain-standard"),
        .package(path: "../../swift-ietf/swift-rfc-4648"),
        .package(path: "../../swift-foundations/swift-ascii"),
        .package(path: "../../swift-primitives/swift-binary-primitives"),
        .package(path: "../../swift-primitives/swift-parser-primitives")
    ],
    targets: [
        // Core URL implementation
        .target(
            name: "WHATWG URL",
            dependencies: [
                .whatwgFormURLEncoded,
                .rfc3987,
                .rfc791,
                .rfc5952,
                .domainStandard,
                .incits41986,
                .binary,
                .product(name: "Parser Primitives", package: "swift-parser-primitives")
            ]
        ),

        // application/x-www-form-urlencoded (Section 5)
        .target(
            name: "WHATWG Form URL Encoded",
            dependencies: [
                .rfc4648,
                .incits41986,
                .binary
            ]
        ),

        // Tests
        .testTarget(
            name: "WHATWG Form URL Encoded Tests",
            dependencies: [
                "WHATWG URL",
            ]
        ),
        .testTarget(
            name: "WHATWG URL Tests",
            dependencies: [
                "WHATWG URL",
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)

extension String {
    var tests: Self { self + " Tests" }
    var foundation: Self { self + " Foundation" }
}

for target in package.targets where ![.system, .binary, .plugin, .macro].contains(target.type) {
    let ecosystem: [SwiftSetting] = [
        .strictMemorySafety(),
        .enableUpcomingFeature("ExistentialAny"),
        .enableUpcomingFeature("InternalImportsByDefault"),
        .enableUpcomingFeature("MemberImportVisibility"),
        .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
        .enableExperimentalFeature("Lifetimes"),
        .enableExperimentalFeature("SuppressedAssociatedTypes"),
    ]

    let package: [SwiftSetting] = []

    target.swiftSettings = (target.swiftSettings ?? []) + ecosystem + package
}
