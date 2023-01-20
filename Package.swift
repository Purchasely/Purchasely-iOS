// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "Purchasely",
    platforms: [
        .iOS(.v11), .tvOS(.v11)
    ],
    products: [
        .library(
            name: "Purchasely",
            targets: ["PurchaselyWrapper"]),
    ],
    targets: [
    .target(
        name: "PurchaselyWrapper",
        dependencies: [
            "Purchasely"
        ],
        path: "Purchasely/PurchaselyWrapper"
    ),
    .binaryTarget(name: "Purchasely", path: "Purchasely/Frameworks/Purchasely.xcframework")
    ]
)
