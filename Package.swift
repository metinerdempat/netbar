// swift-tools-version:5.9
import PackageDescription

// Architecture: all logic lives in the `NetcardioCore` library (testable); the
// `Netcardio` executable is only a thin composition shell (NetcardioApp.swift).
let package = Package(
  name: "Netcardio",
  platforms: [.macOS(.v13)],
  targets: [
    .target(
      name: "NetcardioCore",
      path: "Sources/NetcardioCore"
    ),
    .executableTarget(
      name: "Netcardio",
      dependencies: ["NetcardioCore"],
      path: "Sources/Netcardio"
    ),
    .testTarget(
      name: "NetcardioCoreTests",
      dependencies: ["NetcardioCore"],
      path: "Tests/NetcardioCoreTests"
    )
  ]
)
