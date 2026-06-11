import Foundation

public enum JeevesRuntimeUnavailableReason: String, Codable, Sendable, Equatable {
    case appleIntelligenceNotEnabled
    case deviceNotEligible
    case modelNotReady
    case unsupportedOperatingSystem
    case runtimeDisabled
    case modelNotInstalled
    case unknown
    case adapterUnavailable
    case configurationMissing
    case frameworkUnavailable
    case modelAssetMissing
}

public enum JeevesRuntimeAvailability: Codable, Sendable, Equatable {
    case available
    case unavailable(JeevesRuntimeUnavailableReason)

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

public struct JeevesRuntimeRouteChoice: Codable, Sendable, Equatable {
    public var id: JeevesRuntimeID
    public var displayName: String
    public var availability: JeevesRuntimeAvailability

    public init(
        id: JeevesRuntimeID,
        displayName: String,
        availability: JeevesRuntimeAvailability)
    {
        self.id = id
        self.displayName = displayName
        self.availability = availability
    }
}

public struct JeevesRuntimeCandidate: Sendable {
    public let id: JeevesRuntimeID
    public let displayName: String

    private let availabilityProvider: @Sendable () async -> JeevesRuntimeAvailability
    private let runtimeFactory: @Sendable () async throws -> any JeevesAgentRuntime

    public init(
        id: JeevesRuntimeID,
        displayName: String,
        availability: @escaping @Sendable () async -> JeevesRuntimeAvailability,
        runtime: @escaping @Sendable () async throws -> any JeevesAgentRuntime)
    {
        self.id = id
        self.displayName = displayName
        self.availabilityProvider = availability
        self.runtimeFactory = runtime
    }

    public init(
        runtime: any JeevesAgentRuntime,
        displayName: String? = nil,
        availability: JeevesRuntimeAvailability = .available)
    {
        self.init(
            id: runtime.id,
            displayName: displayName ?? runtime.id.rawValue,
            availability: { availability },
            runtime: { runtime })
    }

    public static func unavailable(
        id: JeevesRuntimeID,
        displayName: String,
        reason: JeevesRuntimeUnavailableReason) -> JeevesRuntimeCandidate
    {
        let availability = JeevesRuntimeAvailability.unavailable(reason)
        return JeevesRuntimeCandidate(
            id: id,
            displayName: displayName,
            availability: { availability },
            runtime: {
                throw JeevesRuntimeRouterError.runtimeUnavailable(id, availability)
            })
    }

    public func availability() async -> JeevesRuntimeAvailability {
        await self.availabilityProvider()
    }

    public func choice() async -> JeevesRuntimeRouteChoice {
        let availability = await self.availability()
        return JeevesRuntimeRouteChoice(
            id: self.id,
            displayName: self.displayName,
            availability: availability)
    }

    func makeRuntime() async throws -> any JeevesAgentRuntime {
        try await self.runtimeFactory()
    }
}

public enum JeevesRuntimeRouterError: Error, Sendable, Equatable, LocalizedError {
    case noCandidates
    case noAvailableRuntime([JeevesRuntimeRouteChoice])
    case runtimeUnavailable(JeevesRuntimeID, JeevesRuntimeAvailability)

    public var errorDescription: String? {
        switch self {
        case .noCandidates:
            "No Jeeves runtimes are configured."
        case .noAvailableRuntime(let choices):
            Self.noAvailableRuntimeDescription(choices)
        case let .runtimeUnavailable(id, availability):
            "Jeeves runtime \(id.rawValue) is \(availability.statusLabel)."
        }
    }

    private static func noAvailableRuntimeDescription(_ choices: [JeevesRuntimeRouteChoice]) -> String {
        let summary = choices
            .map { "\($0.id.rawValue)=\($0.availability.statusLabel)" }
            .joined(separator: ", ")
        return "No Jeeves runtime is available: \(summary)."
    }
}

public final class JeevesRuntimeRouter: @unchecked Sendable, JeevesAgentRuntime {
    public let id: JeevesRuntimeID

    private let candidates: [JeevesRuntimeCandidate]

    public init(candidates: [JeevesRuntimeCandidate], defaultRuntimeID: JeevesRuntimeID? = nil) {
        self.candidates = candidates
        self.id = defaultRuntimeID ?? candidates.first?.id ?? .inMemory
    }

    public func choices() async -> [JeevesRuntimeRouteChoice] {
        var choices: [JeevesRuntimeRouteChoice] = []
        choices.reserveCapacity(self.candidates.count)
        for candidate in self.candidates {
            choices.append(await candidate.choice())
        }
        return choices
    }

    public func selectedRuntimeID(preferredRuntime: JeevesRuntimeID? = nil) async -> JeevesRuntimeID {
        guard let selection = await self.selectCandidate(preferredRuntime: preferredRuntime) else {
            return self.id
        }
        return selection.candidate.id
    }

    public func respond(to turn: JeevesAgentTurn) async throws -> JeevesAgentTurnResult {
        guard let selection = await self.selectCandidate(preferredRuntime: turn.runtimeHints.preferredRuntime) else {
            throw JeevesRuntimeRouterError.noAvailableRuntime(await self.choices())
        }

        let runtime = try await selection.candidate.makeRuntime()
        var result = try await runtime.respond(to: turn)
        result.events.insert(
            JeevesAgentEvent(
                kind: .runtimeSelected,
                message: "Routed turn to \(selection.candidate.displayName).",
                metadata: [
                    "availability": selection.availability.statusLabel,
                    "preferredRuntime": turn.runtimeHints.preferredRuntime?.rawValue ?? "",
                    "runtime": runtime.id.rawValue,
                    "router": "openjeeves-native",
                ]),
            at: 0)
        return result
    }

    private func selectCandidate(preferredRuntime: JeevesRuntimeID?)
        async -> (candidate: JeevesRuntimeCandidate, availability: JeevesRuntimeAvailability)?
    {
        if let preferredRuntime,
           let preferred = await self.availableCandidate(matching: { $0.id == preferredRuntime })
        {
            return preferred
        }

        return await self.availableCandidate(matching: { _ in true })
    }

    private func availableCandidate(
        matching predicate: (JeevesRuntimeCandidate) -> Bool)
        async -> (candidate: JeevesRuntimeCandidate, availability: JeevesRuntimeAvailability)?
    {
        for candidate in self.candidates where predicate(candidate) {
            let availability = await candidate.availability()
            if availability.isAvailable {
                return (candidate, availability)
            }
        }
        return nil
    }
}
