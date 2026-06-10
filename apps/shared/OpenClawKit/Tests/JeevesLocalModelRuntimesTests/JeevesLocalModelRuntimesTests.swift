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
        ])

        #expect(configuration.isEnabled)
        #expect(configuration.modelIdentifier == "mlx-community/Qwen3-4B-4bit")
        #expect(configuration.modelDirectoryURL?.path == "/tmp/mlx-model")
        #expect(configuration.allowsNetworkDownloads)
    }

    @Test
    func mlxCandidateReportsAvailabilitySteps() async {
        let disabled = JeevesMLXRuntimeCandidate.make()

        #expect(await disabled.choice().availability == .unavailable(.runtimeDisabled))

        let missingFramework = JeevesMLXRuntimeCandidate.make(
            configuration: .init(isEnabled: true),
            frameworkImportable: false,
            languageModelSupportImportable: false)

        #expect(await missingFramework.choice().availability == .unavailable(.frameworkUnavailable))

        let missingModel = JeevesMLXRuntimeCandidate.make(
            configuration: .init(isEnabled: true),
            frameworkImportable: true,
            languageModelSupportImportable: true)

        #expect(await missingModel.choice().availability == .unavailable(.modelNotInstalled))

        let missingAdapter = JeevesMLXRuntimeCandidate.make(
            configuration: .init(
                isEnabled: true,
                modelIdentifier: "mlx-community/Qwen3-4B-4bit",
                allowsNetworkDownloads: true),
            frameworkImportable: true,
            languageModelSupportImportable: true)

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
                directoryExists: { _ in true }),
        ])

        let result = try await router.respond(to: Self.turn())

        #expect(result.runtime == .mlx)
    }

    private static func turn() -> JeevesAgentTurn {
        JeevesAgentTurn(
            sessionID: "session",
            input: JeevesAgentMessage(role: .user, content: "Hello"))
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
