import Foundation

public struct JeevesAgentToolDefinition: Codable, Sendable, Equatable, Identifiable {
    public var id: String { self.name }
    public var name: String
    public var description: String
    public var metadata: [String: String]

    public init(
        name: String,
        description: String,
        metadata: [String: String] = [:])
    {
        self.name = name
        self.description = description
        self.metadata = metadata
    }
}

public struct JeevesToolInvocation: Codable, Sendable, Equatable, Identifiable {
    public var id: String
    public var toolName: String
    public var arguments: [String: String]

    public init(
        id: String = UUID().uuidString,
        toolName: String,
        arguments: [String: String] = [:])
    {
        self.id = id
        self.toolName = toolName
        self.arguments = arguments
    }
}

public struct JeevesToolResult: Codable, Sendable, Equatable, Identifiable {
    public var id: String
    public var toolName: String
    public var content: String
    public var metadata: [String: String]

    public init(
        id: String = UUID().uuidString,
        toolName: String,
        content: String,
        metadata: [String: String] = [:])
    {
        self.id = id
        self.toolName = toolName
        self.content = content
        self.metadata = metadata
    }
}

public enum JeevesAgentToolError: Error, Sendable, Equatable, LocalizedError {
    case duplicateTool(String)
    case unknownTool(String)

    public var errorDescription: String? {
        switch self {
        case .duplicateTool(let name):
            "A tool named \(name) is already registered."
        case .unknownTool(let name):
            "No tool named \(name) is registered."
        }
    }
}

public protocol JeevesAgentTool: Sendable {
    var definition: JeevesAgentToolDefinition { get }

    func run(_ invocation: JeevesToolInvocation) async throws -> JeevesToolResult
}

public actor JeevesToolRegistry {
    private var tools: [String: any JeevesAgentTool]

    public init(tools initialTools: [any JeevesAgentTool] = []) throws {
        var toolsByName: [String: any JeevesAgentTool] = [:]
        for tool in initialTools {
            let name = tool.definition.name
            guard toolsByName[name] == nil else {
                throw JeevesAgentToolError.duplicateTool(name)
            }
            toolsByName[name] = tool
        }
        self.tools = toolsByName
    }

    public func register(_ tool: any JeevesAgentTool) throws {
        let name = tool.definition.name
        guard self.tools[name] == nil else {
            throw JeevesAgentToolError.duplicateTool(name)
        }
        self.tools[name] = tool
    }

    public func definitions() -> [JeevesAgentToolDefinition] {
        self.tools.values
            .map { $0.definition }
            .sorted { $0.name < $1.name }
    }

    public func run(_ invocation: JeevesToolInvocation) async throws -> JeevesToolResult {
        guard let tool = self.tools[invocation.toolName] else {
            throw JeevesAgentToolError.unknownTool(invocation.toolName)
        }
        return try await tool.run(invocation)
    }
}

public struct JeevesRuntimeStatusTool: JeevesAgentTool {
    public let definition = JeevesAgentToolDefinition(
        name: "jeeves.runtime.status",
        description: "Reports whether the native OpenJeeves agent core is available.",
        metadata: ["risk": "readOnly"])

    public init() {}

    public func run(_ invocation: JeevesToolInvocation) async throws -> JeevesToolResult {
        JeevesToolResult(
            toolName: invocation.toolName,
            content: "OpenJeeves native agent core is available.",
            metadata: [
                "status": "available",
                "risk": "readOnly",
            ])
    }
}
