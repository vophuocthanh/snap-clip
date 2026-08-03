// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "SnapClip",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        .executableTarget(
            name: "SnapClip",
            path: "Sources/SnapClip",
            swiftSettings: [
                .swiftLanguageMode(.v5)
            ],
            linkerSettings: [
                .linkedLibrary("sqlite3")
            ]
        ),
        .testTarget(
            name: "SnapClipTests",
            dependencies: ["SnapClip"],
            path: "Tests/SnapClipTests",
            swiftSettings: [
                .swiftLanguageMode(.v5)
            ]
        )
    ]
)
