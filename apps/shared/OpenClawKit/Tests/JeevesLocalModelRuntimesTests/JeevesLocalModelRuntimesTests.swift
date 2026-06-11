import Foundation
import JeevesAgentCore
@testable import JeevesLocalModelRuntimes
import Testing

struct JeevesLocalModelRuntimesTests {
    @Test
    func coreAIConfigurationReadsEnvironment() {
        let configuration = JeevesCoreAIRuntimeConfiguration.from(environment: [
            "OPENJEEVES_COREAI_ENABLED": "yes",
            "OPENJEEVES_COREAI_MODEL_PATH": "/tmp/model.aimodel",
            "OPENJEEVES_COREAI_FUNCTION": "generate",
        ])

        #expect(configuration.isEnabled)
        #expect(configuration.modelURL?.path == "/tmp/model.aimodel")
        #expect(configuration.functionName == "generate")
    }

    @Test
    func coreAICandidateReportsDisabledByDefault() async {
        let candidate = JeevesCoreAIRuntimeCandidate.make()

        let choice = await candidate.choice()

        #expect(choice.id == .coreAI)
        #expect(choice.availability == .unavailable(.runtimeDisabled))
    }

    @Test
    func coreAICandidateReportsFrameworkAndModelAvailability() async {
        let missingFramework = JeevesCoreAIRuntimeCandidate.make(
            configuration: .init(isEnabled: true),
            frameworkImportable: false)

        #expect(await missingFramework.choice().availability == .unavailable(.frameworkUnavailable))

        let missingConfiguration = JeevesCoreAIRuntimeCandidate.make(
            configuration: .init(isEnabled: true),
            frameworkImportable: true)

        #expect(await missingConfiguration.choice().availability == .unavailable(.configurationMissing))

        let missingModel = JeevesCoreAIRuntimeCandidate.make(
            configuration: .init(isEnabled: true, modelURL: URL(fileURLWithPath: "/tmp/missing.aimodel")),
            frameworkImportable: true,
            fileExists: { _ in false })

        #expect(await missingModel.choice().availability == .unavailable(.modelAssetMissing))
    }

    @Test
    func coreAICandidateUsesInjectedRuntimeWhenReady() async throws {
        let router = JeevesRuntimeRouter(candidates: [
            JeevesCoreAIRuntimeCandidate.make(
                configuration: .init(isEnabled: true, modelURL: URL(fileURLWithPath: "/tmp/model.aimodel")),
                runtime: TestRuntime(id: .coreAI),
                frameworkImportable: true,
                fileExists: { _ in true }),
        ])

        let result = try await router.respond(to: Self.turn())

        #expect(result.runtime == .coreAI)
    }

    @Test
    func mlxConfigurationReadsEnvironment() {
        let configuration = JeevesMLXRuntimeConfiguration.from(environment: [
            "OPENJEEVES_MLX_ENABLED": "true",
            "OPENJEEVES_MLX_MODEL_ID": "mlx-community/Qwen3-4B-4bit",
            "OPENJEEVES_MLX_MODEL_DIR": "/tmp/mlx-model",
            "OPENJEEVES_MLX_ALLOW_DOWNLOADS": "on",
            "OPENJEEVES_MLX_MODEL_KIND": "vlm",
            "OPENJEEVES_MLX_MAX_TOKENS": "128",
        ])

        #expect(configuration.isEnabled)
        #expect(configuration.modelIdentifier == "mlx-community/Qwen3-4B-4bit")
        #expect(configuration.modelDirectoryURL?.path == "/tmp/mlx-model")
        #expect(configuration.allowsNetworkDownloads)
        #expect(configuration.modelKind == .vision)
        #expect(configuration.maxTokens == 128)
    }

    @Test
    func mlxCatalogPrefersVisionCapableInstalledModels() throws {
        let root = try Self.makeTemporaryDirectory()
        try Self.makeHuggingFaceSnapshot(
            root: root,
            identifier: "mlx-community/Text-4bit",
            vision: false)
        let visionDirectory = try Self.makeHuggingFaceSnapshot(
            root: root,
            identifier: "mlx-community/Vision-4bit",
            vision: true)

        let installed = JeevesMLXModelCatalog.installedModels(searchRoots: [root])

        #expect(installed.map(\.identifier) == ["mlx-community/Vision-4bit", "mlx-community/Text-4bit"])
        #expect(installed.first?.kind == .vision)
        #expect(installed.first?.directoryURL.resolvingSymlinksInPath() == visionDirectory.resolvingSymlinksInPath())
    }

    @Test
    func mlxConfigurationCanDiscoverInstalledVisionModel() throws {
        let root = try Self.makeTemporaryDirectory()
        let directory = try Self.makeHuggingFaceSnapshot(
            root: root,
            identifier: "mlx-community/Qwen-VL-4bit",
            vision: true)

        let configuration = JeevesMLXRuntimeConfiguration.from(
            environment: [:],
            discoverInstalledModels: true,
            searchRoots: [root])

        #expect(configuration.isEnabled)
        #expect(configuration.modelIdentifier == "mlx-community/Qwen-VL-4bit")
        #expect(configuration.modelDirectoryURL?.resolvingSymlinksInPath() == directory.resolvingSymlinksInPath())
        #expect(configuration.modelKind == .vision)
    }

    @Test
    func mlxCandidateReportsAvailabilitySteps() async {
        let disabled = JeevesMLXRuntimeCandidate.make()

        #expect(await disabled.choice().availability == .unavailable(.runtimeDisabled))

        let missingFramework = JeevesMLXRuntimeCandidate.make(
            configuration: .init(isEnabled: true),
            frameworkImportable: false,
            languageModelSupportImportable: false,
            visionModelSupportImportable: false)

        #expect(await missingFramework.choice().availability == .unavailable(.frameworkUnavailable))

        let missingModel = JeevesMLXRuntimeCandidate.make(
            configuration: .init(isEnabled: true),
            frameworkImportable: true,
            languageModelSupportImportable: true,
            visionModelSupportImportable: true)

        #expect(await missingModel.choice().availability == .unavailable(.modelNotInstalled))

        let missingAdapter = JeevesMLXRuntimeCandidate.make(
            configuration: .init(
                isEnabled: true,
                modelDirectoryURL: URL(fileURLWithPath: "/tmp/mlx-model", isDirectory: true)),
            frameworkImportable: true,
            languageModelSupportImportable: true,
            visionModelSupportImportable: true,
            createDefaultRuntime: false,
            directoryExists: { _ in true })

        #expect(await missingAdapter.choice().availability == .unavailable(.adapterUnavailable))
    }

    @Test
    func mlxCandidateUsesInjectedRuntimeWhenReady() async throws {
        let router = JeevesRuntimeRouter(candidates: [
            JeevesMLXRuntimeCandidate.make(
                configuration: .init(
                    isEnabled: true,
                    modelDirectoryURL: URL(fileURLWithPath: "/tmp/mlx-model", isDirectory: true)),
                runtime: TestRuntime(id: .mlx),
                frameworkImportable: true,
                languageModelSupportImportable: true,
                visionModelSupportImportable: true,
                createDefaultRuntime: false,
                directoryExists: { _ in true }),
        ])

        let result = try await router.respond(to: Self.turn())

        #expect(result.runtime == .mlx)
    }

    @Test
    func mlxVisionCandidateUsesVisionRuntimeID() async throws {
        let router = JeevesRuntimeRouter(candidates: [
            JeevesMLXRuntimeCandidate.make(
                configuration: .init(
                    isEnabled: true,
                    modelDirectoryURL: URL(fileURLWithPath: "/tmp/mlx-vlm", isDirectory: true),
                    modelKind: .vision),
                runtime: TestRuntime(id: .mlxVLM),
                frameworkImportable: true,
                languageModelSupportImportable: true,
                visionModelSupportImportable: true,
                createDefaultRuntime: false,
                directoryExists: { _ in true }),
        ])

        let choices = await router.choices()
        let result = try await router.respond(to: Self.turn())

        #expect(choices.first?.id == .mlxVLM)
        #expect(choices.first?.displayName == "MLX VLM")
        #expect(result.runtime == .mlxVLM)
    }

    private static func turn() -> JeevesAgentTurn {
        JeevesAgentTurn(
            sessionID: "session",
            input: JeevesAgentMessage(role: .user, content: "Hello"))
    }

    private static func makeTemporaryDirectory() throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("JeevesLocalModelRuntimesTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    @discardableResult
    private static func makeHuggingFaceSnapshot(
        root: URL,
        identifier: String,
        vision: Bool) throws -> URL
    {
        let modelDirectory = root.appendingPathComponent(
            "models--\(identifier.replacingOccurrences(of: "/", with: "--"))",
            isDirectory: true)
        let snapshotDirectory = modelDirectory
            .appendingPathComponent("snapshots", isDirectory: true)
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: snapshotDirectory, withIntermediateDirectories: true)
        let config: [String: Any] = vision
            ? [
                "model_type": "qwen_vl",
                "vision_config": [:],
                "text_config": [:],
            ]
            : ["model_type": "qwen2"]
        let configData = try JSONSerialization.data(withJSONObject: config, options: [.sortedKeys])
        try configData.write(to: snapshotDirectory.appendingPathComponent("config.json"))
        try Data("{}".utf8).write(to: snapshotDirectory.appendingPathComponent("tokenizer.json"))
        try Data("{}".utf8).write(to: snapshotDirectory.appendingPathComponent("model.safetensors.index.json"))
        return snapshotDirectory
    }
}

private struct TestRuntime: JeevesAgentRuntime {
    let id: JeevesRuntimeID

    func respond(to turn: JeevesAgentTurn) async throws -> JeevesAgentTurnResult {
        JeevesAgentTurnResult(
            message: JeevesAgentMessage(role: .assistant, content: turn.input.content),
            runtime: self.id)
    }
}
