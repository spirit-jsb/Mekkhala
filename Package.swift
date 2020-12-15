// swift-tools-version:5.2
import PackageDescription

let package = Package(
  name: "Mekkhala",
  platforms: [
    .iOS(.v10)
  ],
  products: [
    .library(name: "Mekkhala", targets: ["Mekkhala"]),
  ],
  targets: [
    .target(name: "Mekkhala", path: "Sources"),
  ],
  swiftLanguageVersions: [
    .v5
  ]
)