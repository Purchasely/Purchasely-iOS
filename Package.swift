// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "Purchasely",
    products: [
        .library(
            name: "Purchasely",
            targets: ["Purchasely"]),
    ],
    targets: [
        .binaryTarget(name: "Purchasely", path: "Purchasely/Frameworks/Purchasely.xcframework")
    ]
)
