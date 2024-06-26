// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AarleKeychain",
    platforms: [
        .iOS(.v16),
        .macOS(.v13)
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "AarleKeychain",
            targets: ["AarleKeychain"]),
    ],
    dependencies: [
        .package(path: "../Types"),
        .package(url: "https://github.com/kishikawakatsumi/KeychainAccess.git", from: "3.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "AarleKeychain",
            dependencies: ["Types", "KeychainAccess"]),
        .testTarget(
            name: "AarleKeychainTests",
            dependencies: ["AarleKeychain"]),
    ]
)
