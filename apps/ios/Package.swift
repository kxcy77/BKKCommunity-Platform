// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "BKKCommunity",
    platforms: [.iOS(.v16), .macOS(.v13)],
    products: [
        .executable(name: "BKKCommunity", targets: ["BKKCommunity"])
    ],
    targets: [
        .executableTarget(
            name: "BKKCommunity",
            path: "BKKCommunity"
        )
    ]
)
