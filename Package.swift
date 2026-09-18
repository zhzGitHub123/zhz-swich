// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ZSwich",
    platforms: [.macOS(.v15)],
    targets: [
        .executableTarget(
            name: "ZSwich",
            path: "Sources/ZSwich"
        )
    ]
)
