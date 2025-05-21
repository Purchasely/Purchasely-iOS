// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "PurchaselyExampleApp",
    platforms: [.iOS(.v16)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "PurchaselyExampleApp",
            targets: ["PurchaselyExampleApp"]),
    ],
    dependencies: [
        .package(url: "https://github.com/Purchasely/Purchasely-iOS", from: .init(5, 2, 1)),
        .package(url: "https://github.com/airbnb/lottie-spm.git", from: .init(4, 5, 1)),
        .package(url: "https://github.com/AliSoftware/OHHTTPStubs.git", from: .init(9, 1, 0))
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "PurchaselyExampleApp",
            dependencies: [
                .product(name: "Purchasely", package: "purchasely-ios"),
                .product(name: "Lottie", package: "lottie-spm"),
                .product(name: "OHHTTPStubs", package: "OHHTTPStubs")
            ],
            resources: [
                .process("Assets.xcassets")
            ]
        )
    ]
)
