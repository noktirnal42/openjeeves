import Foundation

public enum JeevesAgentRole: String, Codable, Sendable, Equatable {
    case system
    case user
    case assistant
    case tool
}

public struct JeevesAgentMessage: Codable, Sendable, Equatable, Identifiable {
    public var id: String
    public var role: JeevesAgentRole
    public var content: String
    public var metadata: [String: String]

    public init(
        id: String = UUID().uuidString,
        role: JeevesAgentRole,
        content: String,
        metadata: [String: String] = [:])
    {
        self.id = id
        self.role = role
        self.content = content
        self.metadata = metadata
    }
}

public struct JeevesAgentTurn: Codable, Sendable, Equatable, Identifiable {
    public var id: String
    public var sessionID: String
    public var input: JeevesAgentMessage
    public var history: [JeevesAgentMessage]
    public var runtimeHints: JeevesRuntimeHints

    public init(
        id: String = UUID().uuidString,
        sessionID: String,
        input: JeevesAgentMessage,
        history: [JeevesAgentMessage] = [],
        runtimeHints: JeevesRuntimeHints = .init())
    {
        self.id = id
        self.sessionID = sessionID
        self.input = input
        self.history = history
        self.runtimeHints = runtimeHints
    }
}

public struct JeevesRuntimeHints: Codable, Sendable, Equatable {
    public var preferredRuntime: JeevesRuntimeID?
    public var allowCloudEscalation: Bool
    public var userLocaleIdentifier: String?

    public init(
        preferredRuntime: JeevesRuntimeID? = nil,
        allowCloudEscalation: Bool = false,
        userLocaleIdentifier: String? = nil)
    {
        self.preferredRuntime = preferredRuntime
        self.allowCloudEscalation = allowCloudEscalation
        self.userLocaleIdentifier = userLocaleIdentifier
    }
}

public enum JeevesRuntimeID: String, Codable, Sendable, Equatable, CaseIterable {
    case foundationModels
    case foundationModelsCloud
    case coreAI
    case mlx
    case compatibilityBridge
    case inMemory
}

public struct JeevesAgentTurnResult: Codable, Sendable, Equatable {
    public var message: JeevesAgentMessage
    public var runtime: JeevesRuntimeID
    public var events: [JeevesAgentEvent]

    public init(
        message: JeevesAgentMessage,
        runtime: JeevesRuntimeID,
        events: [JeevesAgentEvent] = [])
    {
        self.message = message
        self.runtime = runtime
        self.events = events
    }
}

public struct JeevesAgentEvent: Codable, Sendable, Equatable, Identifiable {
    public enum Kind: String, Codable, Sendable {
        case turnStarted
        case turnCompleted
        case runtimeSelected
        case toolRequested
        case toolCompleted
    }

    public var id: String
    public var kind: Kind
    public var message: String
    public var metadata: [String: String]

    public init(
        id: String = UUID().uuidString,
        kind: Kind,
        message: String,
        metadata: [String: String] = [:])
    {
        self.id = id
        self.kind = kind
        self.message = message
        self.metadata = metadata
    }
}

public protocol JeevesAgentRuntime: Sendable {
    var id: JeevesRuntimeID { get }

    func respond(to turn: JeevesAgentTurn) async throws -> JeevesAgentTurnResult
}

public actor JeevesAgentSession {
    public let id: String
    private var messages: [JeevesAgentMessage]

    public init(id: String = UUID().uuidString, messages: [JeevesAgentMessage] = []) {
        self.id = id
        self.messages = messages
    }

    public func history() -> [JeevesAgentMessage] {
        self.messages
    }

    public func append(_ message: JeevesAgentMessage) {
        self.messages.append(message)
    }

    public func run(
        input: JeevesAgentMessage,
        runtime: any JeevesAgentRuntime,
        hints: JeevesRuntimeHints = .init()) async throws -> JeevesAgentTurnResult
    {
        let turn = JeevesAgentTurn(
            sessionID: self.id,
            input: input,
            history: self.messages,
            runtimeHints: hints)
        self.messages.append(input)
        let result = try await runtime.respond(to: turn)
        self.messages.append(result.message)
        return result
    }
}
