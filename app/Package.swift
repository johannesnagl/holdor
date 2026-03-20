// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Holdor",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "Holdor",
            path: "Sources/Holdor",
            exclude: ["Resources/AppIcon.icns"]
        )
    ]
)
