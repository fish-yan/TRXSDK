// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "TRXSDK",
    platforms: [
        .iOS(.v13),
        .macOS(.v12),
    ],
    products: [
        .library(
            name: "TRXSDK",
            targets: ["TRXSDK"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/krzyzanowskim/CryptoSwift.git", exact: "1.8.4"),
        .package(url: "https://github.com/pebble8888/ed25519swift.git", exact: "1.2.8"),
        .package(url: "https://github.com/21-DOT-DEV/swift-secp256k1.git", exact: "0.10.0"),
        .package(url: "https://github.com/apple/swift-protobuf.git", exact: "1.29.0"),
        .package(url: "https://github.com/google/grpc-binary.git", exact: "1.69.1"),
    ],
    targets: [
        .target(
            name: "TRXSDKGRPC",
            dependencies: [
                .product(name: "gRPC-Core", package: "grpc-binary"),
                .product(name: "gRPC-C++", package: "grpc-binary"),
            ],
            path: "Sources/TRXSDKGRPC"
        ),
        .target(
            name: "TRXSDK",
            dependencies: [
                "CryptoSwift",
                "ed25519swift",
                .product(name: "secp256k1", package: "swift-secp256k1"),
                .product(name: "SwiftProtobuf", package: "swift-protobuf"),
                "TRXSDKGRPC",
            ],
            path: "Sources/TRXSDK"
        ),
        .testTarget(
            name: "TRXSDKTests",
            dependencies: ["TRXSDK"],
            path: "Tests/TRXSDKTests"
        ),
    ]
)
