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
