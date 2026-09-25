// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ScreenTranslate",
    platforms: [.macOS(.v15)],
    targets: [
        .executableTarget(
            name: "ScreenTranslate",
            path: "Sources/ScreenTranslate",
            exclude: ["Info.plist"],
            swiftSettings: [.swiftLanguageMode(.v5)]
        )
    ]
)
