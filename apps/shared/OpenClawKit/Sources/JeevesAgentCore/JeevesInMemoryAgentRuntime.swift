import Foundation

public struct JeevesInMemoryAgentRuntime: JeevesAgentRuntime {
    public let id: JeevesRuntimeID = .inMemory
    private let responseBuilder: @Sendable (JeevesAgentTurn) -> String

    public init(responseBuilder: @escaping @Sendable (JeevesAgentTurn) -> String = Self.defaultResponse) {
        self.responseBuilder = responseBuilder
    }

    public func respond(to turn: JeevesAgentTurn) async throws -> JeevesAgentTurnResult {
        let response = self.responseBuilder(turn)
        let message = JeevesAgentMessage(role: .assistant, content: response)
        return JeevesAgentTurnResult(
            message: message,
            runtime: self.id,
            events: [
                JeevesAgentEvent(
                    kind: .runtimeSelected,
                    message: "Selected in-memory runtime.",
                    metadata: ["runtime": self.id.rawValue]),
                JeevesAgentEvent(
                    kind: .turnCompleted,
                    message: "Generated deterministic in-memory response."),
            ])
    }

    public static func defaultResponse(turn: JeevesAgentTurn) -> String {
        let trimmed = turn.input.content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return "I am ready."
        }
        return "Jeeves heard: \(trimmed)"
    }
}
