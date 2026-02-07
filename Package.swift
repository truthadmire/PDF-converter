// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "PDFConverter",
    platforms: [
        .macOS(.v13),
    ],
    products: [
        .library(
            name: "PDFConverter",
            targets: ["PDFConverter"]
        ),
    ],
    targets: [
        .target(
            name: "PDFConverter"
        ),
        .testTarget(
            name: "PDFConverterTests",
            dependencies: ["PDFConverter"]
        ),
    ]
)
