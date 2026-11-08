// swift-tools-version: 5.9
//
// The apps are built from Whatch.xcodeproj. This manifest only exists so the pure
// logic in Shared/Core can be unit-tested from the command line with `swift test`.

import PackageDescription

let package = Package(
    name: "WhatchCore",
    platforms: [.macOS(.v14), .iOS(.v17), .watchOS(.v10)],
    products: [
        .library(name: "WhatchCore", targets: ["WhatchCore"]),
    ],
    targets: [
        .target(name: "WhatchCore", path: "Shared/Core"),
        .testTarget(name: "WhatchCoreTests", dependencies: ["WhatchCore"], path: "Tests/WhatchCoreTests"),
    ]
)
