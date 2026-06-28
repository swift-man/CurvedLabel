// swift-tools-version: 6.0
import PackageDescription

let package = Package(
  name: "CurvedLabel",
  platforms: [
    .iOS(.v15),
    .tvOS(.v15)
  ],
  products: [
    .library(
      name: "CurvedLabel",
      targets: ["CurvedLabel"]
    )
  ],
  targets: [
    .target(
      name: "CurvedLabel",
      path: "Sources/CurvedLabel"
    ),
    .testTarget(
      name: "CurvedLabelTests",
      dependencies: ["CurvedLabel"],
      path: "Tests/CurvedLabelTests"
    )
  ],
  swiftLanguageModes: [.v6]
)
