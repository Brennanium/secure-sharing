// swift-tools-version: 6.4

import PackageDescription

let package = Package(
  name: "SecureSharing",
  platforms: [
    .iOS(.v16),
    .macOS(.v12),
    .tvOS(.v16),
    .visionOS(.v1),
  ],
  products: [
    .library(name: "SecureSharing", targets: ["SecureSharing"])
  ],
  dependencies: [
    .package(url: "https://github.com/pointfreeco/swift-concurrency-extras", from: "1.3.0"),
    .package(url: "https://github.com/pointfreeco/swift-dependencies", from: "1.5.1"),
    .package(url: "https://github.com/pointfreeco/swift-issue-reporting", from: "2.1.0"),
    .package(url: "https://github.com/pointfreeco/swift-sharing", from: "2.0.0"),
  ],
  targets: [
    .target(
      name: "SecureSharing",
      dependencies: [
        .product(name: "ConcurrencyExtras", package: "swift-concurrency-extras"),
        .product(name: "Dependencies", package: "swift-dependencies"),
        .product(name: "IssueReporting", package: "swift-issue-reporting"),
        .product(name: "Sharing", package: "swift-sharing"),
      ],
      resources: [.process("PrivacyInfo.xcprivacy")],
      swiftSettings: [.enableUpcomingFeature("NonisolatedNonsendingByDefault")]
    ),
    .testTarget(
      name: "SecureSharingTests",
      dependencies: [
        "SecureSharing",
        .product(name: "DependenciesTestSupport", package: "swift-dependencies"),
      ]
    ),
  ]
)
