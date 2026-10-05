// swift-tools-version: 5.7
import PackageDescription

let package = Package(
  name: "MaziSandigi", platforms: [.macOS(.v11)],
  products: [
    .executable(name: "MaziSandigi", targets: ["MaziSandigi"]),
    .library(name: "MaziCore", targets: ["MaziCore"]),
    .executable(name: "MaziRulesTests", targets: ["MaziRulesTests"]),
  ],
  targets: [
    .target(name: "MaziCore"),
    .executableTarget(name: "MaziSandigi", dependencies: ["MaziCore"]),
    .executableTarget(
      name: "MaziRulesTests", dependencies: ["MaziCore"], path: "Tests/MaziCoreTests"),
  ], swiftLanguageVersions: [.v5])
