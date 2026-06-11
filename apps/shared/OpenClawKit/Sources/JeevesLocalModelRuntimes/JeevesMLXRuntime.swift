import Foundation
import JeevesAgentCore

#if canImport(MLXLLM) && canImport(MLXVLM)
#if canImport(MLXLMCommon) && canImport(MLXHuggingFace)
#if canImport(Tokenizers)
import CoreImage
import MLXHuggingFace
import MLXLLM
import MLXLMCommon
import MLXVLM
import Tokenizers

public enum JeevesMLXRuntimeError: Error, Sendable, Equatable, LocalizedError {
    case modelDirectoryRequired
    case imageDecodeFailed(String)

    public var errorDescription: String? {
        switch self {
        case .modelDirectoryRequired:
            "MLX local runtime requires OPENJEEVES_MLX_MODEL_DIR or an installed Hugging Face snapshot."
        case .imageDecodeFailed(let fileName):
            "MLX VLM could not decode image attachment '\(fileName)'."
        }
    }
}

public final class JeevesMLXRuntime: @unchecked Sendable, JeevesAgentRuntime {
    public let id: JeevesRuntimeID

    private let configuration: JeevesMLXRuntimeConfiguration
    private let instructions: String?
    private let state = JeevesMLXRuntimeState()

    public init(configuration: JeevesMLXRuntimeConfiguration, instructions: String? = nil) {
        self.configuration = configuration
        self.instructions = instructions
        self.id = configuration.modelKind.runtimeID
    }

    public func respond(to turn: JeevesAgentTurn) async throws -> JeevesAgentTurnResult {
        let container = try await self.state.container(configuration: self.configuration)
        let parameters = GenerateParameters(maxTokens: self.configuration.maxTokens)
        let session = ChatSession(
            container,
            instructions: self.instructions,
            generateParameters: parameters)
        let prompt = Self.prompt(for: turn)
        let images = try Self.images(from: turn.input.attachments)
        let response = try await session.respond(to: prompt, images: images, videos: [])
        let trimmed = response.trimmingCharacters(in: .whitespacesAndNewlines)
        return JeevesAgentTurnResult(
            message: JeevesAgentMessage(role: .assistant, content: trimmed),
            runtime: self.id,
            events: [
                JeevesAgentEvent(
                    kind: .runtimeSelected,
                    message: "Selected \(self.configuration.modelKind.displayName) runtime.",
                    metadata: [
                        "runtime": self.id.rawValue,
                        "model": self.configuration.modelIdentifier ?? "",
                        "modelDirectory": self.configuration.modelDirectoryURL?.path ?? "",
                    ]),
                JeevesAgentEvent(
                    kind: .turnCompleted,
                    message: "Generated response with \(self.configuration.modelKind.displayName).",
                    metadata: ["runtime": self.id.rawValue]),
            ])
    }

    private static func prompt(for turn: JeevesAgentTurn) -> String {
        let history = turn.history.suffix(8).map { message in
            "\(Self.roleLabel(message.role)): \(message.content.trimmingCharacters(in: .whitespacesAndNewlines))"
        }
        let current = "User: \(turn.input.content.trimmingCharacters(in: .whitespacesAndNewlines))"
        return (history + [current]).joined(separator: "\n")
    }

    private static func roleLabel(_ role: JeevesAgentRole) -> String {
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

    private static func images(from attachments: [JeevesAgentAttachment]) throws -> [UserInput.Image] {
        try attachments.filter(\.isImage).map { attachment in
            guard let image = CIImage(data: attachment.data) else {
                throw JeevesMLXRuntimeError.imageDecodeFailed(attachment.fileName)
            }
            return .ciImage(image)
        }
    }
}

private actor JeevesMLXRuntimeState {
    private var container: ModelContainer?

    func container(configuration: JeevesMLXRuntimeConfiguration) async throws -> ModelContainer {
        if let container {
            return container
        }
        guard let directory = configuration.modelDirectoryURL else {
            throw JeevesMLXRuntimeError.modelDirectoryRequired
        }
        let loader = #huggingFaceTokenizerLoader()
        let loaded: ModelContainer
        switch configuration.modelKind {
        case .text:
            loaded = try await LLMModelFactory.shared.loadContainer(from: directory, using: loader)
        case .vision:
            loaded = try await VLMModelFactory.shared.loadContainer(from: directory, using: loader)
        }
        self.container = loaded
        return loaded
    }
}
#endif
#endif
#endif
