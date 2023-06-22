// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MarkdownView",
    platforms: [
      .macOS(.v12),
      .iOS(.v15),
      .tvOS(.v15),
      .watchOS(.v8),
    ],
    products: [
        .library(name: "MarkdownView", targets: ["MarkdownView"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-markdown.git", from: "0.2.0"),
        .package(url: "https://github.com/raspu/Highlightr.git", from: "2.1.2"),
    ],
    targets: [
        .target(
            name: "MarkdownView",
            dependencies: [
                .product(name: "Markdown", package: "swift-markdown"),
                .product(
                    name: "Highlightr",
                    package: "Highlightr",
                    condition: .when(platforms: [.iOS, .macOS])
                ),
            ],
            swiftSettings: [.unsafeFlags([
                "--target x86_64-apple-ios11.0-simulator",
                "--sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator15.5.sdk"
            ], .when(configuration: .debug))]
        ),
    ]
)
