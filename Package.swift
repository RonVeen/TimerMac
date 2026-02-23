// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "TimerMac",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "TimerMac", targets: ["TimerMac"])
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "TimerMac",
            path: "Sources",
            linkerSettings: [
                .linkedLibrary("sqlite3")
            ]
        ),
        .testTarget(
            name: "TimerMacTests",
            dependencies: ["TimerMac"]
        )
    ]
)
