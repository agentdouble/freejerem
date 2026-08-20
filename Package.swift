// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "FreeJerem",
    platforms: [.macOS(.v13)],
    products: [
        .library(name: "FreeJeremCore", targets: ["FreeJeremCore"]),
        .executable(name: "FreeJerem", targets: ["FreeJeremApp"]),
        .executable(name: "FreeJeremCoreChecks", targets: ["FreeJeremCoreChecks"])
    ],
    targets: [
        .target(name: "FreeJeremCore"),
        .executableTarget(name: "FreeJeremApp", dependencies: ["FreeJeremCore"]),
        .executableTarget(name: "FreeJeremCoreChecks", dependencies: ["FreeJeremCore"])
    ]
)
