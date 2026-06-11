// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "OpenClawKit",
    platforms: [
        .iOS(.v18),
        .macOS(.v15),
    ],
    products: [
        .library(name: "JeevesAgentCore", targets: ["JeevesAgentCore"]),
        .library(name: "JeevesFoundationModelsRuntime", targets: ["JeevesFoundationModelsRuntime"]),
        .library(name: "JeevesLocalModelRuntimes", targets: ["JeevesLocalModelRuntimes"]),
        .library(name: "OpenClawProtocol", targets: ["OpenClawProtocol"]),
        .library(name: "OpenClawKit", targets: ["OpenClawKit"]),
        .library(name: "OpenClawChatUI", targets: ["OpenClawChatUI"]),
    ],
    dependencies: [
        .package(url: "https://github.com/steipete/ElevenLabsKit", exact: "0.1.0"),
        .package(url: "https://github.com/gonzalezreal/textual", exact: "0.3.1"),
        .package(url: "https://github.com/ml-explore/mlx-swift-lm", exact: "3.31.3"),
        .package(url: "https://github.com/huggingface/swift-transformers", from: "1.3.0"),
    ],
    targets: [
        .target(
            name: "JeevesAgentCore",
            path: "Sources/JeevesAgentCore",
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency"),
            ]),
        .target(
            name: "JeevesFoundationModelsRuntime",
            dependencies: ["JeevesAgentCore"],
            path: "Sources/JeevesFoundationModelsRuntime",
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency"),
            ]),
        .target(
            name: "JeevesLocalModelRuntimes",
            dependencies: [
                "JeevesAgentCore",
                .product(name: "MLXLLM", package: "mlx-swift-lm"),
                .product(name: "MLXVLM", package: "mlx-swift-lm"),
                .product(name: "MLXLMCommon", package: "mlx-swift-lm"),
                .product(name: "MLXHuggingFace", package: "mlx-swift-lm"),
                .product(name: "Tokenizers", package: "swift-transformers"),
            ],
            path: "Sources/JeevesLocalModelRuntimes",
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency"),
            ]),
        .target(
            name: "OpenClawProtocol",
            path: "Sources/OpenClawProtocol",
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency"),
            ]),
        .target(
            name: "OpenClawKit",
            dependencies: [
                "OpenClawProtocol",
                .product(name: "ElevenLabsKit", package: "ElevenLabsKit"),
            ],
            path: "Sources/OpenClawKit",
            resources: [
                .process("Resources"),
            ],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency"),
            ]),
        .target(
            name: "OpenClawChatUI",
            dependencies: [
                "JeevesAgentCore",
                "OpenClawKit",
                .product(
                    name: "Textual",
                    package: "textual",
                    condition: .when(platforms: [.macOS, .iOS])),
            ],
            path: "Sources/OpenClawChatUI",
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency"),
            ]),
        .testTarget(
            name: "OpenClawKitTests",
            dependencies: ["OpenClawKit", "OpenClawChatUI"],
            path: "Tests/OpenClawKitTests",
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency"),
                .enableExperimentalFeature("SwiftTesting"),
            ]),
        .testTarget(
            name: "JeevesAgentCoreTests",
            dependencies: ["JeevesAgentCore"],
            path: "Tests/JeevesAgentCoreTests",
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency"),
                .enableExperimentalFeature("SwiftTesting"),
            ]),
        .testTarget(
            name: "JeevesFoundationModelsRuntimeTests",
            dependencies: ["JeevesAgentCore", "JeevesFoundationModelsRuntime"],
            path: "Tests/JeevesFoundationModelsRuntimeTests",
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency"),
                .enableExperimentalFeature("SwiftTesting"),
            ]),
        .testTarget(
            name: "JeevesLocalModelRuntimesTests",
            dependencies: ["JeevesAgentCore", "JeevesLocalModelRuntimes"],
            path: "Tests/JeevesLocalModelRuntimesTests",
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency"),
                .enableExperimentalFeature("SwiftTesting"),
            ]),
    ])
