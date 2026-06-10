import Foundation
import JeevesAgentCore

#if canImport(MLX)
import MLX
#endif

#if canImport(MLXLLM)
import MLXLLM
#endif

#if canImport(MLXLMCommon)
import MLXLMCommon
#endif

public struct JeevesMLXRuntimeConfiguration: Codable, Sendable, Equatable {
    public var isEnabled: Bool
    public var modelIdentifier: String?
    public var modelDirectoryURL: URL?
    public var allowsNetworkDownloads: Bool

    public init(
        isEnabled: Bool = false,
        modelIdentifier: String? = nil,
        modelDirectoryURL: URL? = nil,
        allowsNetworkDownloads: Bool = false)
    {
        self.isEnabled = isEnabled
        self.modelIdentifier = modelIdentifier
        self.modelDirectoryURL = modelDirectoryURL
        self.allowsNetworkDownloads = allowsNetworkDownloads
    }

    public static func from(environment: [String: String]) -> JeevesMLXRuntimeConfiguration {
        JeevesMLXRuntimeConfiguration(
            isEnabled: Self.boolValue(environment["OPENJEEVES_MLX_ENABLED"]) ?? false,
            modelIdentifier: Self.trimmed(environment["OPENJEEVES_MLX_MODEL_ID"]),
            modelDirectoryURL: Self.directoryURL(environment["OPENJEEVES_MLX_MODEL_DIR"]),
            allowsNetworkDownloads: Self.boolValue(environment["OPENJEEVES_MLX_ALLOW_DOWNLOADS"]) ?? false)
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

    private static func directoryURL(_ raw: String?) -> URL? {
        guard let trimmed = Self.trimmed(raw) else { return nil }
        return URL(fileURLWithPath: trimmed, isDirectory: true)
    }

    private static func trimmed(_ raw: String?) -> String? {
        let trimmed = raw?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? nil : trimmed
    }
}

public enum JeevesMLXRuntimeCandidate {
    public static var isFrameworkImportable: Bool {
#if canImport(MLX)
        true
#else
        false
#endif
    }

    public static var isLanguageModelSupportImportable: Bool {
#if canImport(MLXLLM) && canImport(MLXLMCommon)
        true
#else
        false
#endif
    }

    public static func make(
        configuration: JeevesMLXRuntimeConfiguration = .init(),
        runtime: (any JeevesAgentRuntime)? = nil,
        frameworkImportable: Bool = Self.isFrameworkImportable,
        languageModelSupportImportable: Bool = Self.isLanguageModelSupportImportable,
        directoryExists: @escaping @Sendable (URL) -> Bool = { url in
            var isDirectory = ObjCBool(false)
            let exists = FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory)
            return exists && isDirectory.boolValue
        }) -> JeevesRuntimeCandidate
    {
        JeevesRuntimeCandidate(
            id: .mlx,
            displayName: "MLX",
            availability: {
                self.availability(
                    configuration: configuration,
                    runtime: runtime,
                    frameworkImportable: frameworkImportable,
                    languageModelSupportImportable: languageModelSupportImportable,
                    directoryExists: directoryExists)
            },
            runtime: {
                guard let runtime else {
                    throw JeevesRuntimeRouterError.runtimeUnavailable(
                        .mlx,
                        self.availability(
                            configuration: configuration,
                            runtime: runtime,
                            frameworkImportable: frameworkImportable,
                            languageModelSupportImportable: languageModelSupportImportable,
                            directoryExists: directoryExists))
                }
                return runtime
            })
    }

    private static func availability(
        configuration: JeevesMLXRuntimeConfiguration,
        runtime: (any JeevesAgentRuntime)?,
        frameworkImportable: Bool,
        languageModelSupportImportable: Bool,
        directoryExists: @Sendable (URL) -> Bool) -> JeevesRuntimeAvailability
    {
        guard configuration.isEnabled else {
            return .unavailable(.runtimeDisabled)
        }
        guard frameworkImportable, languageModelSupportImportable else {
            return .unavailable(.frameworkUnavailable)
        }
        if let modelDirectoryURL = configuration.modelDirectoryURL {
            guard directoryExists(modelDirectoryURL) else {
                return .unavailable(.modelAssetMissing)
            }
        } else if configuration.modelIdentifier == nil || !configuration.allowsNetworkDownloads {
            return .unavailable(.modelNotInstalled)
        }
        guard runtime != nil else {
            return .unavailable(.adapterUnavailable)
        }
        return .available
    }
}
