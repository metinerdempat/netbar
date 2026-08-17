// swift-tools-version:5.9
import PackageDescription

// Mimari: tüm mantık `NetBarCore` kütüphanesinde (test edilebilir), `NetBar`
// yürütülebiliri yalnızca ince bir kompozisyon kabuğudur (main.swift).
let package = Package(
  name: "NetBar",
  platforms: [.macOS(.v13)],
  targets: [
    .target(
      name: "NetBarCore",
      path: "Sources/NetBarCore"
    ),
    .executableTarget(
      name: "NetBar",
      dependencies: ["NetBarCore"],
      path: "Sources/NetBar"
    ),
    .testTarget(
      name: "NetBarCoreTests",
      dependencies: ["NetBarCore"],
      path: "Tests/NetBarCoreTests"
    )
  ]
)
