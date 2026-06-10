import JeevesAgentCore

public enum JeevesFoundationModelsRuntimeCandidate {
    public static func make(
        instructions: String? = nil,
        promptBuilder: JeevesFoundationModelsPromptBuilder = .init()) -> JeevesRuntimeCandidate
    {
#if canImport(FoundationModels)
        if #available(iOS 26.0, macOS 26.0, visionOS 26.0, *) {
            return JeevesRuntimeCandidate(
                id: .foundationModels,
                displayName: "Foundation Models",
                availability: {
                    JeevesRuntimeAvailability(JeevesFoundationModelsSupport.currentAvailability())
                },
                runtime: {
                    JeevesFoundationModelsRuntime(
                        instructions: instructions,
                        promptBuilder: promptBuilder)
                })
        }
#endif
        return .unavailable(
            id: .foundationModels,
            displayName: "Foundation Models",
            reason: .unsupportedOperatingSystem)
    }
}

public extension JeevesRuntimeAvailability {
    init(_ availability: JeevesFoundationModelsAvailability) {
        switch availability {
        case .available:
            self = .available
        case .unavailable(let reason):
            self = .unavailable(JeevesRuntimeUnavailableReason(reason))
        }
    }
}

private extension JeevesRuntimeUnavailableReason {
    init(_ reason: JeevesFoundationModelsUnavailableReason) {
        switch reason {
        case .appleIntelligenceNotEnabled:
            self = .appleIntelligenceNotEnabled
        case .deviceNotEligible:
            self = .deviceNotEligible
        case .modelNotReady:
            self = .modelNotReady
        case .unsupportedOperatingSystem:
            self = .unsupportedOperatingSystem
        case .unknown:
            self = .unknown
        }
    }
}
