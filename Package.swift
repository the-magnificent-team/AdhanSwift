// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AdhanSwift",
    platforms: [.macOS(.v14), .iOS(.v16), .tvOS(.v16) ] ,
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "AdhanSwift",
            targets: ["AdhanSwift"]),
        
    ],
    dependencies: [.package(url: "https://github.com/davedelong/time", from: "1.0.1")],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "AdhanSwift", dependencies: [.product(name: "Time", package: "time")]),
        .testTarget(
            name: "AdhanSwiftTests",
            dependencies: ["AdhanSwift"]),
    ]
)
