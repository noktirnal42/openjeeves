import Foundation
import JeevesAgentCore

#if canImport(FoundationModels)
import FoundationModels
#endif

public enum JeevesFoundationModelsUnavailableReason: String, Codable, Sendable, Equatable {
    case appleIntelligenceNotEnabled
    case deviceNotEligible
    case modelNotReady
    case unsupportedOperatingSystem
    case unknown
}

public enum JeevesFoundationModelsAvailability: Codable, Sendable, Equatable {
    case available
    case unavailable(JeevesFoundationModelsUnavailableReason)

    public var isAvailable: Bool {
        switch self {
        case .available:
            true
        case .unavailable:
            false
        }
    }

    public var statusLabel: String {
        switch self {
        case .available:
            "available"
        case .unavailable(let reason):
            reason.rawValue
        }
    }
}

public enum JeevesFoundationModelsSupport {
    public static func currentAvailability() -> JeevesFoundationModelsAvailability {
#if canImport(FoundationModels)
        if #available(iOS 26.0, macOS 26.0, visionOS 26.0, *) {
            return JeevesFoundationModelsAvailability(SystemLanguageModel.default.availability)
        }
#endif
        return .unavailable(.unsupportedOperatingSystem)
    }
}

public enum JeevesFoundationModelsRuntimeError: Error, Sendable, Equatable, LocalizedError {
    case unavailable(JeevesFoundationModelsAvailability)

    public var errorDescription: String? {
        switch self {
        case .unavailable(let availability):
            "Foundation Models runtime is \(availability.statusLabel)."
        }
    }
}

#if canImport(FoundationModels)
@available(iOS 26.0, macOS 26.0, visionOS 26.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
public struct JeevesFoundationModelsRuntime: JeevesAgentRuntime {
    public let id: JeevesRuntimeID = .foundationModels

    private let model: SystemLanguageModel
    private let instructions: String?
    private let promptBuilder: JeevesFoundationModelsPromptBuilder

    public init(
        model: SystemLanguageModel = .default,
        instructions: String? = nil,
        promptBuilder: JeevesFoundationModelsPromptBuilder = .init())
    {
        self.model = model
        self.instructions = instructions
        self.promptBuilder = promptBuilder
    }

    public var availability: JeevesFoundationModelsAvailability {
        JeevesFoundationModelsAvailability(self.model.availability)
    }

    public func respond(to turn: JeevesAgentTurn) async throws -> JeevesAgentTurnResult {
        let availability = self.availability
        guard availability.isAvailable else {
            throw JeevesFoundationModelsRuntimeError.unavailable(availability)
        }

        let session = LanguageModelSession(model: self.model, instructions: self.instructions)
        let prompt = self.promptBuilder.prompt(for: turn)
        let response = try await session.respond(to: prompt)
        let message = JeevesAgentMessage(role: .assistant, content: response.content)

        return JeevesAgentTurnResult(
            message: message,
            runtime: self.id,
            events: [
                JeevesAgentEvent(
                    kind: .runtimeSelected,
                    message: "Selected Foundation Models runtime.",
                    metadata: [
                        "runtime": self.id.rawValue,
                        "availability": availability.statusLabel,
                    ]),
                JeevesAgentEvent(
                    kind: .turnCompleted,
                    message: "Generated response with Foundation Models.",
                    metadata: ["runtime": self.id.rawValue]),
            ])
    }
}

@available(iOS 26.0, macOS 26.0, visionOS 26.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
private extension JeevesFoundationModelsAvailability {
    init(_ availability: SystemLanguageModel.Availability) {
        switch availability {
        case .available:
            self = .available
        case .unavailable(let reason):
            self = .unavailable(JeevesFoundationModelsUnavailableReason(reason))
        }
    }
}

@available(iOS 26.0, macOS 26.0, visionOS 26.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
private extension JeevesFoundationModelsUnavailableReason {
    init(_ reason: SystemLanguageModel.Availability.UnavailableReason) {
        switch reason {
        case .appleIntelligenceNotEnabled:
            self = .appleIntelligenceNotEnabled
        case .deviceNotEligible:
            self = .deviceNotEligible
        case .modelNotReady:
            self = .modelNotReady
        @unknown default:
            self = .unknown
        }
    }
}
#endif
