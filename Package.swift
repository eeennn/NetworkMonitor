// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "NetworkMonitor",
    targets: [
        .executableTarget(
            name: "NetworkMonitor",
            swiftSettings: [
                .unsafeFlags(["-Xswiftc", "-disable-arena-checks", "-Xswiftc", "-concurrency-implicit-main-thread-actor-on"]),
            ]
        ),
    ]
)
