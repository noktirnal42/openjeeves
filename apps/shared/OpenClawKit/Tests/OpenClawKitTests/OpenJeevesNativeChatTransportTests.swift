import JeevesAgentCore
import OpenClawKit
import Testing
@testable import OpenClawChatUI

@Suite(.serialized)
struct OpenJeevesNativeChatTransportTests {
    @Test
    func transportStoresNativeSessionHistoryAndEmitsFinalEvent() async throws {
        let transport = OpenJeevesNativeChatTransport()
        let stream = transport.events()

        let response = try await transport.sendMessage(
            sessionKey: "main",
            message: "Hello native runtime",
            thinking: "off",
            idempotencyKey: "run-1",
            attachments: [])

        #expect(response.runId == "run-1")
        #expect(response.status == "ok")

        var iterator = stream.makeAsyncIterator()
        let event = await iterator.next()
        if case let .chat(payload) = event {
            #expect(payload.runId == "run-1")
            #expect(payload.sessionKey == "main")
            #expect(payload.state == "final")
        } else {
            Issue.record("Expected final chat event.")
        }

        let history = try await transport.requestHistory(sessionKey: "main")
        let messages = history.messages?.compactMap {
            try? ChatPayloadDecoding.decode($0, as: OpenClawChatMessage.self)
        } ?? []

        #expect(messages.map(\.role) == ["user", "assistant"])
        #expect(messages.first?.content.first?.text == "Hello native runtime")
        #expect(messages.last?.content.first?.text == "Jeeves heard: Hello native runtime")
    }

    @Test
    func viewModelCanSendThroughNativeTransport() async throws {
        let transport = OpenJeevesNativeChatTransport()
        let viewModel = await MainActor.run {
            OpenClawChatViewModel(sessionKey: "main", transport: transport)
        }

        await MainActor.run { viewModel.load() }
        try await waitUntil("native chat bootstrap") {
            await MainActor.run { viewModel.healthOK && !viewModel.isLoading }
        }

        await MainActor.run {
            viewModel.input = "Plan the next native step"
            viewModel.send()
        }

        try await waitUntil("native chat response") {
            await MainActor.run {
                viewModel.pendingRunCount == 0 &&
                    viewModel.messages.contains { message in
                        message.role == "assistant" &&
                            message.content.first?.text == "Jeeves heard: Plan the next native step"
                    }
            }
        }
    }

    @Test
    func resetClearsNativeSessionHistory() async throws {
        let transport = OpenJeevesNativeChatTransport()
        _ = try await transport.sendMessage(
            sessionKey: "main",
            message: "Before reset",
            thinking: "off",
            idempotencyKey: "run-1",
            attachments: [])

        try await transport.resetSession(sessionKey: "main")

        let history = try await transport.requestHistory(sessionKey: "main")
        #expect(history.messages?.isEmpty == true)
    }

    @Test
    func sessionListReportsConfiguredNativeRuntime() async throws {
        let transport = OpenJeevesNativeChatTransport(runtime: TestRuntime(id: .mlx))

        let sessions = try await transport.listSessions(limit: nil)

        #expect(sessions.defaults?.model == "openjeeves/mlx")
        #expect(sessions.sessions.first?.model == "mlx")
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

private func waitUntil(
    _ description: String,
    timeout: Duration = .seconds(2),
    condition: @escaping @Sendable () async -> Bool) async throws
{
    let clock = ContinuousClock()
    let deadline = clock.now.advanced(by: timeout)
    while clock.now < deadline {
        if await condition() { return }
        try await Task.sleep(for: .milliseconds(20))
    }
    Issue.record("Timed out waiting for \(description).")
}
