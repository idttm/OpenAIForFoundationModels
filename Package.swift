// swift-tools-version: 6.2
import PackageDescription

let package = Package(
  name: "OpenAIForFoundationModels",
  // Every OS where Foundation Models supports server-side language models.
  // Spelled as strings because the .v27 constants require tools-version 6.4.
  platforms: [
    .iOS("27.0"), .macOS("27.0"), .visionOS("27.0"), .watchOS("27.0"),
  ],
  products: [
    .library(
      name: "OpenAIForFoundationModels",
      targets: ["OpenAIForFoundationModels"]
    )
  ],
  targets: [
    // Low-level OpenAI Responses API client. No FoundationModels dependency.
    .target(name: "OpenAIAPI"),

    // FoundationModels ↔ OpenAI bridge.
    .target(
      name: "OpenAIForFoundationModels",
      dependencies: ["OpenAIAPI"]
    ),

    // Runnable usage example (`swift run OpenAIExample`).
    .executableTarget(
      name: "OpenAIExample",
      dependencies: ["OpenAIForFoundationModels"],
      path: "Examples/OpenAIExample"
    ),

    .testTarget(
      name: "OpenAIAPITests",
      dependencies: ["OpenAIAPI"]
    ),
    .testTarget(
      name: "OpenAIForFoundationModelsTests",
      dependencies: ["OpenAIForFoundationModels"]
    ),
  ]
)
