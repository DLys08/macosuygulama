// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "DesktopDuzen",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "DesktopDuzen", targets: ["DesktopDuzen"])
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "DesktopDuzen",
            dependencies: [],
            path: "Sources/DesktopDuzen",
            exclude: ["Resources/README.md"]
        ),
        .testTarget(
            name: "DesktopDuzenTests",
            dependencies: ["DesktopDuzen"],
            path: "Tests/DesktopDuzenTests"
        )
    ]
)
