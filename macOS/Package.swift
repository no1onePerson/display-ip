// swift-tools-version: 6.0
import PackageDescription
let package = Package(name: "PrismCore", platforms: [.macOS(.v14)], products: [.library(name: "PrismCore", targets: ["PrismCore"])], targets: [.target(name: "PrismCore", path: "Core"), .target(name: "PrismShared", path: "Shared"), .testTarget(name: "PrismCoreTests", dependencies: ["PrismCore", "PrismShared"], path: "Tests")])
