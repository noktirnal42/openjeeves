import Testing
@testable import JeevesAgentCore

struct JeevesAgentCoreTests {
    @Test
    func inMemoryRuntimeProducesDeterministicAssistantMessage() async throws {
        let runtime = JeevesInMemoryAgentRuntime()
        let turn = JeevesAgentTurn(
            sessionID: "session-1",
            input: JeevesAgentMessage(role: .user, content: "Plan the native runtime"))

        let result = try await runtime.respond(to: turn)

        #expect(result.runtime == .inMemory)
        #expect(result.message.role == .assistant)
        #expect(result.message.content == "Jeeves heard: Plan the native runtime")
        #expect(result.events.map(\.kind) == [.runtimeSelected, .turnCompleted])
    }

    @Test
    func sessionPersistsUserAndAssistantMessagesInOrder() async throws {
        let runtime = JeevesInMemoryAgentRuntime { turn in
            "History count: \(turn.history.count)"
        }
        let session = JeevesAgentSession(id: "session-1")

        _ = try await session.run(input: JeevesAgentMessage(role: .user, content: "First"), runtime: runtime)
        _ = try await session.run(input: JeevesAgentMessage(role: .user, content: "Second"), runtime: runtime)

        let history = await session.history()
        #expect(history.map(\.role) == [.user, .assistant, .user, .assistant])
        #expect(history.map(\.content) == ["First", "History count: 0", "Second", "History count: 2"])
    }

    @Test
    func runtimeHintsDefaultToLocalOnly() {
        let hints = JeevesRuntimeHints()

        #expect(hints.preferredRuntime == nil)
        #expect(hints.allowCloudEscalation == false)
        #expect(hints.userLocaleIdentifier == nil)
    }

    @Test
    func toolRegistryRunsRegisteredStatusTool() async throws {
        let registry = try JeevesToolRegistry(tools: [JeevesRuntimeStatusTool()])

        let result = try await registry.run(JeevesToolInvocation(toolName: "jeeves.runtime.status"))

        #expect(result.toolName == "jeeves.runtime.status")
        #expect(result.content == "OpenJeeves native agent core is available.")
        #expect(result.metadata["risk"] == "readOnly")
    }

    @Test
    func toolRegistryDefinitionsAreStableAndSorted() async throws {
        let registry = try JeevesToolRegistry(tools: [
            TestTool(name: "jeeves.zeta"),
            TestTool(name: "jeeves.alpha"),
        ])

        let definitions = await registry.definitions()

        #expect(definitions.map(\.name) == ["jeeves.alpha", "jeeves.zeta"])
    }

    @Test
    func toolRegistryReportsUnknownToolWithClosedError() async throws {
        let registry = try JeevesToolRegistry()

        do {
            _ = try await registry.run(JeevesToolInvocation(toolName: "jeeves.missing"))
        } catch let error as JeevesAgentToolError {
            #expect(error == .unknownTool("jeeves.missing"))
            return
        }

        Issue.record("Expected unknown tool error.")
    }

    @Test
    func runtimeRouterFallsBackToFirstAvailableRuntime() async throws {
        let router = JeevesRuntimeRouter(candidates: [
            .unavailable(id: .foundationModels, displayName: "Foundation Models", reason: .modelNotReady),
            JeevesRuntimeCandidate(runtime: TestRuntime(id: .inMemory, response: "fallback")),
        ])
        let turn = JeevesAgentTurn(
            sessionID: "session-1",
            input: JeevesAgentMessage(role: .user, content: "Hello"),
            runtimeHints: JeevesRuntimeHints(preferredRuntime: .foundationModels))

        let result = try await router.respond(to: turn)

        #expect(result.runtime == .inMemory)
        #expect(result.message.content == "fallback: Hello")
        #expect(result.events.first?.metadata["router"] == "openjeeves-native")
    }

    @Test
    func runtimeRouterHonorsAvailablePreferredRuntime() async throws {
        let router = JeevesRuntimeRouter(candidates: [
            JeevesRuntimeCandidate(runtime: TestRuntime(id: .foundationModels, response: "foundation")),
            JeevesRuntimeCandidate(runtime: TestRuntime(id: .mlx, response: "mlx")),
        ])
        let turn = JeevesAgentTurn(
            sessionID: "session-1",
            input: JeevesAgentMessage(role: .user, content: "Route"),
            runtimeHints: JeevesRuntimeHints(preferredRuntime: .mlx))

        let result = try await router.respond(to: turn)

        #expect(result.runtime == .mlx)
        #expect(result.message.content == "mlx: Route")
    }

    @Test
    func runtimeRouterReportsUnavailableChoices() async throws {
        let router = JeevesRuntimeRouter(candidates: [
            .unavailable(id: .coreAI, displayName: "Core AI", reason: .runtimeDisabled),
            .unavailable(id: .mlx, displayName: "MLX", reason: .modelNotInstalled),
        ])

        let choices = await router.choices()

        #expect(choices.map(\.id) == [.coreAI, .mlx])
        #expect(choices.map(\.availability.statusLabel) == ["runtimeDisabled", "modelNotInstalled"])

        do {
            _ = try await router.respond(to: JeevesAgentTurn(
                sessionID: "session-1",
                input: JeevesAgentMessage(role: .user, content: "No runtime")))
        } catch let error as JeevesRuntimeRouterError {
            if case .noAvailableRuntime(let reported) = error {
                #expect(reported == choices)
                return
            }
            Issue.record("Expected noAvailableRuntime.")
            return
        }

        Issue.record("Expected router to throw when every runtime is unavailable.")
    }
}

private struct TestTool: JeevesAgentTool {
    let definition: JeevesAgentToolDefinition

    init(name: String) {
        self.definition = JeevesAgentToolDefinition(
            name: name,
            description: "Test tool")
    }

    func run(_ invocation: JeevesToolInvocation) async throws -> JeevesToolResult {
        JeevesToolResult(toolName: invocation.toolName, content: "ok")
    }
}

private struct TestRuntime: JeevesAgentRuntime {
    let id: JeevesRuntimeID
    let response: String

    func respond(to turn: JeevesAgentTurn) async throws -> JeevesAgentTurnResult {
        JeevesAgentTurnResult(
            message: JeevesAgentMessage(role: .assistant, content: "\(self.response): \(turn.input.content)"),
            runtime: self.id)
    }
}
