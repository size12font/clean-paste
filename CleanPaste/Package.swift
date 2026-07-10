// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "CleanPaste",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(name: "ClipCore", targets: ["ClipCore"]),
        .library(name: "CleanPasteMacCore", targets: ["CleanPasteMacCore"]),
        .executable(name: "CleanPasteMac", targets: ["CleanPasteMac"]),
        .executable(name: "CleanPasteQA", targets: ["CleanPasteQA"]),
        .executable(name: "CleanPasteFixtureCapture", targets: ["CleanPasteFixtureCapture"]),
        .executable(name: "CleanPasteShortcutQA", targets: ["CleanPasteShortcutQA"]),
        .executable(name: "CleanPasteTargetSmoke", targets: ["CleanPasteTargetSmoke"])
    ],
    targets: [
        .target(name: "ClipCore"),
        .target(
            name: "CleanPasteMacCore",
            dependencies: ["ClipCore"],
            path: "CleanPasteMac/CleanPasteMacCore"
        ),
        .executableTarget(
            name: "CleanPasteMac",
            dependencies: ["CleanPasteMacCore"],
            path: "CleanPasteMac/CleanPasteMac"
        ),
        .executableTarget(
            name: "CleanPasteQA",
            dependencies: ["ClipCore", "CleanPasteMacCore"],
            path: "Tools/CleanPasteQA"
        ),
        .executableTarget(
            name: "CleanPasteFixtureCapture",
            dependencies: ["ClipCore"],
            path: "Tools/CleanPasteFixtureCapture"
        ),
        .executableTarget(
            name: "CleanPasteShortcutQA",
            dependencies: ["ClipCore"],
            path: "Tools/CleanPasteShortcutQA"
        ),
        .executableTarget(
            name: "CleanPasteTargetSmoke",
            dependencies: ["ClipCore", "CleanPasteMacCore"],
            path: "Tools/CleanPasteTargetSmoke"
        ),
        .testTarget(
            name: "ClipCoreTests",
            dependencies: ["ClipCore"],
            resources: [.copy("Fixtures")]
        ),
        .testTarget(
            name: "CleanPasteMacTests",
            dependencies: ["CleanPasteMacCore"],
            path: "CleanPasteMac/CleanPasteMacTests"
        )
    ]
)
