import Foundation
import JeevesAgentCore
import JeevesFoundationModelsRuntime
import OpenClawChatUI
import OpenClawKit
import OSLog

enum OpenJeevesNativeChatFeature {
    private static let defaultsKey = "openjeeves.nativeChat.enabled"
    private static let environmentKey = "OPENJEEVES_NATIVE_CHAT"
    private static let logger = Logger(subsystem: "ai.openclaw", category: "ios.native-chat")
    private static let foundationModelsInstructions = """
    You are Jeeves, a native Apple-platform agent for OpenJeeves.
    Be concise, practical, and clear about actions that require local permissions or unavailable capabilities.
    """

    static var isEnabled: Bool {
        self.isEnabled(
            environment: ProcessInfo.processInfo.environment,
            defaults: .standard)
    }

    static func isEnabled(environment: [String: String], defaults: UserDefaults) -> Bool {
        if let envValue = environment[self.environmentKey] {
            return self.boolValue(from: envValue) ?? false
        }
        guard defaults.object(forKey: self.defaultsKey) != nil else {
            return false
        }
        return defaults.bool(forKey: self.defaultsKey)
    }

    static func makeTransport(gateway: GatewayNodeSession) -> any OpenClawChatTransport {
        self.makeTransport(
            gateway: gateway,
            environment: ProcessInfo.processInfo.environment,
            defaults: .standard)
    }

    static func makeTransport(
        gateway: GatewayNodeSession,
        environment: [String: String],
        defaults: UserDefaults) -> any OpenClawChatTransport
    {
        guard self.isEnabled(environment: environment, defaults: defaults) else {
            return IOSGatewayChatTransport(gateway: gateway)
        }
        return OpenJeevesNativeChatTransport(runtime: self.makeNativeRuntime())
    }

    private static func makeNativeRuntime() -> any JeevesAgentRuntime {
        self.logger.info("OpenJeeves iOS native chat using runtime router.")
        return JeevesRuntimeRouter(
            candidates: self.nativeRuntimeCandidates(),
            defaultRuntimeID: .foundationModels)
    }

    private static func nativeRuntimeCandidates() -> [JeevesRuntimeCandidate] {
        [
            JeevesFoundationModelsRuntimeCandidate.make(instructions: self.foundationModelsInstructions),
            .unavailable(id: .coreAI, displayName: "Core AI", reason: .runtimeDisabled),
            .unavailable(id: .mlx, displayName: "MLX", reason: .modelNotInstalled),
            JeevesRuntimeCandidate(runtime: JeevesInMemoryAgentRuntime(), displayName: "Native In-Memory"),
        ]
    }

    private static func boolValue(from raw: String) -> Bool? {
        switch raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "1", "true", "yes", "on":
            true
        case "0", "false", "no", "off":
            false
        default:
            nil
        }
    }
}
