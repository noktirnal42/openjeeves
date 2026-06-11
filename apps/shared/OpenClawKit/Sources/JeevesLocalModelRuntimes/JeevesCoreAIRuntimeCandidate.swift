import Foundation
import JeevesAgentCore

#if canImport(CoreAI)
import CoreAI
#endif

public struct JeevesCoreAIRuntimeConfiguration: Codable, Sendable, Equatable {
    public var isEnabled: Bool
    public var modelURL: URL?
    public var functionName: String?

    public init(
        isEnabled: Bool = false,
        modelURL: URL? = nil,
        functionName: String? = nil)
    {
        self.isEnabled = isEnabled
        self.modelURL = modelURL
        self.functionName = functionName
    }

    public static func from(environment: [String: String]) -> JeevesCoreAIRuntimeConfiguration {
        JeevesCoreAIRuntimeConfiguration(
            isEnabled: Self.boolValue(environment["OPENJEEVES_COREAI_ENABLED"]) ?? false,
            modelURL: Self.fileURL(environment["OPENJEEVES_COREAI_MODEL_PATH"]),
            functionName: Self.trimmed(environment["OPENJEEVES_COREAI_FUNCTION"]))
    }

    private static func boolValue(_ raw: String?) -> Bool? {
        guard let raw else { return nil }
        return switch raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "1", "true", "yes", "on":
            true
        case "0", "false", "no", "off":
            false
        default:
            nil
        }
    }

    private static func fileURL(_ raw: String?) -> URL? {
        guard let trimmed = Self.trimmed(raw) else { return nil }
        return URL(fileURLWithPath: trimmed, isDirectory: false)
    }

    private static func trimmed(_ raw: String?) -> String? {
        let trimmed = raw?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? nil : trimmed
    }
}

public enum JeevesCoreAIRuntimeCandidate {
    public static var isFrameworkImportable: Bool {
#if canImport(CoreAI)
        true
#else
        false
#endif
    }

    public static func make(
        configuration: JeevesCoreAIRuntimeConfiguration = .init(),
        runtime: (any JeevesAgentRuntime)? = nil,
        frameworkImportable: Bool = Self.isFrameworkImportable,
        fileExists: @escaping @Sendable (URL) -> Bool = { url in
            FileManager.default.fileExists(atPath: url.path)
        }) -> JeevesRuntimeCandidate
    {
        JeevesRuntimeCandidate(
            id: .coreAI,
            displayName: "Core AI",
            availability: {
                self.availability(
                    configuration: configuration,
                    runtime: runtime,
                    frameworkImportable: frameworkImportable,
                    fileExists: fileExists)
            },
            runtime: {
                guard let runtime else {
                    throw JeevesRuntimeRouterError.runtimeUnavailable(
                        .coreAI,
                        self.availability(
                            configuration: configuration,
                            runtime: runtime,
                            frameworkImportable: frameworkImportable,
                            fileExists: fileExists))
                }
                return runtime
            })
    }

    private static func availability(
        configuration: JeevesCoreAIRuntimeConfiguration,
        runtime: (any JeevesAgentRuntime)?,
        frameworkImportable: Bool,
        fileExists: @Sendable (URL) -> Bool) -> JeevesRuntimeAvailability
    {
        guard configuration.isEnabled else {
            return .unavailable(.runtimeDisabled)
        }
        guard frameworkImportable else {
            return .unavailable(.frameworkUnavailable)
        }
        guard let modelURL = configuration.modelURL else {
            return .unavailable(.configurationMissing)
        }
        guard fileExists(modelURL) else {
            return .unavailable(.modelAssetMissing)
        }
        guard runtime != nil else {
            return .unavailable(.adapterUnavailable)
        }
        return .available
    }
}
