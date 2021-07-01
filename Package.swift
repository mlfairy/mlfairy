// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MLFairy",
	platforms: [.iOS(.v13), .macOS(.v10_15), .watchOS(.v6), .tvOS(.v13)],
    products: [
        .library(name: "MLFairy", targets: ["MLFairy"]),
    ],
    dependencies: [
		.package(url: "https://github.com/Alamofire/Alamofire.git",.exact("5.4.3")),
		.package(url: "https://github.com/krzyzanowskim/CryptoSwift.git",.exact("1.4.0")),
		.package(name: "MLFSupport", url: "https://github.com/mlfairy/sdk-support-spm",.exact("0.0.12"))
    ],
    targets: [
        .target(name: "MLFairy", dependencies: ["Alamofire", "CryptoSwift", "MLFSupport"]),
		.testTarget( name: "MLFairyTests", dependencies: ["MLFairy"], resources: [.copy("Files"), .copy("Models")]),
    ]
)
