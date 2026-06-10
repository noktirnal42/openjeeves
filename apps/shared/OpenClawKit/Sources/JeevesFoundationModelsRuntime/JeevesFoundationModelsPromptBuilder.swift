import Foundation
import JeevesAgentCore

public struct JeevesFoundationModelsPromptBuilder: Sendable, Equatable {
    public var maxHistoryMessages: Int

    public init(maxHistoryMessages: Int = 12) {
        self.maxHistoryMessages = max(0, maxHistoryMessages)
    }

    public func prompt(for turn: JeevesAgentTurn) -> String {
        var lines: [String] = []
        let history = turn.history.suffix(self.maxHistoryMessages)

        if !history.isEmpty {
            lines.append("Conversation so far:")
            lines.append(contentsOf: history.map(Self.formatHistoryMessage(_:)))
            lines.append("")
        }

        lines.append("User: \(turn.input.content.trimmingCharacters(in: .whitespacesAndNewlines))")
        lines.append("Assistant:")
        return lines.joined(separator: "\n")
    }

    private static func formatHistoryMessage(_ message: JeevesAgentMessage) -> String {
        "\(Self.label(for: message.role)): \(message.content)"
    }

    private static func label(for role: JeevesAgentRole) -> String {
        switch role {
        case .system:
            "System"
        case .user:
            "User"
        case .assistant:
            "Assistant"
        case .tool:
            "Tool"
        }
    }
}
