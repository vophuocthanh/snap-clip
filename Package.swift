// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "CopyClipPro",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        .executableTarget(
            name: "CopyClipPro",
            path: "Sources/CopyClipPro",
            swiftSettings: [
                .swiftLanguageMode(.v5)
            ],
            linkerSettings: [
                .linkedLibrary("sqlite3")
            ]
        ),
        .testTarget(
            name: "CopyClipProTests",
            dependencies: ["CopyClipPro"],
            path: "Tests/CopyClipProTests",
            swiftSettings: [
                .swiftLanguageMode(.v5)
            ]
        )
    ]
)
