import Foundation
import JeevesAgentCore

#if canImport(MLX)
import MLX
#endif

#if canImport(MLXLLM)
import MLXLLM
#endif

#if canImport(MLXVLM)
import MLXVLM
#endif

#if canImport(MLXLMCommon)
import MLXLMCommon
#endif

#if canImport(MLXHuggingFace)
import MLXHuggingFace
#endif

#if canImport(Tokenizers)
import Tokenizers
#endif

public enum JeevesMLXModelKind: String, Codable, Sendable, Equatable, CaseIterable {
    case text
    case vision

    public var runtimeID: JeevesRuntimeID {
        switch self {
        case .text:
            .mlx
        case .vision:
            .mlxVLM
        }
    }

    public var displayName: String {
        switch self {
        case .text:
            "MLX"
        case .vision:
            "MLX VLM"
        }
    }
}

public struct JeevesMLXInstalledModel: Codable, Sendable, Equatable {
    public var identifier: String
    public var directoryURL: URL
    public var kind: JeevesMLXModelKind

    public init(identifier: String, directoryURL: URL, kind: JeevesMLXModelKind) {
        self.identifier = identifier
        self.directoryURL = directoryURL
        self.kind = kind
    }
}

public enum JeevesMLXModelCatalog {
    public static func defaultSearchRoots(homeDirectory: URL = Self.defaultHomeDirectory()) -> [URL] {
        [
            homeDirectory.appendingPathComponent(".cache/huggingface/hub", isDirectory: true),
            homeDirectory.appendingPathComponent(".cache/mlx", isDirectory: true),
        ]
    }

    public static func preferredInstalledModel(
        searchRoots: [URL] = Self.defaultSearchRoots(),
        fileManager: FileManager = .default) -> JeevesMLXInstalledModel?
    {
        self.installedModels(searchRoots: searchRoots, fileManager: fileManager).first
    }

    public static func installedModels(
        searchRoots: [URL] = Self.defaultSearchRoots(),
        fileManager: FileManager = .default) -> [JeevesMLXInstalledModel]
    {
        let models = searchRoots.flatMap { root in
            self.installedModels(in: root, fileManager: fileManager)
        }
        return models.sorted { lhs, rhs in
            if lhs.kind != rhs.kind {
                return lhs.kind == .vision
            }
            return lhs.identifier.localizedStandardCompare(rhs.identifier) == .orderedAscending
        }
    }

    public static func modelKind(at directoryURL: URL, fileManager: FileManager = .default) -> JeevesMLXModelKind? {
        guard let config = self.configJSON(at: directoryURL, fileManager: fileManager) else { return nil }
        if self.isVisionConfig(config, directoryURL: directoryURL, fileManager: fileManager) {
            return .vision
        }
        return .text
    }

    private static func installedModels(in root: URL, fileManager: FileManager) -> [JeevesMLXInstalledModel] {
        guard let children = try? fileManager.contentsOfDirectory(
            at: root,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles])
        else {
            return []
        }

        var models: [JeevesMLXInstalledModel] = []
        for child in children where child.lastPathComponent.hasPrefix("models--mlx-community--") {
            let identifier = child.lastPathComponent
                .dropFirst("models--".count)
                .replacingOccurrences(of: "--", with: "/")
            let snapshotsURL = child.appendingPathComponent("snapshots", isDirectory: true)
            guard let snapshots = try? fileManager.contentsOfDirectory(
                at: snapshotsURL,
                includingPropertiesForKeys: [.isDirectoryKey],
                options: [.skipsHiddenFiles])
            else {
                continue
            }
            for snapshot in snapshots {
                guard self.hasRequiredModelFiles(at: snapshot, fileManager: fileManager),
                      let kind = self.modelKind(at: snapshot, fileManager: fileManager)
                else {
                    continue
                }
                models.append(JeevesMLXInstalledModel(
                    identifier: identifier,
                    directoryURL: snapshot,
                    kind: kind))
            }
        }
        return models
    }

    private static func hasRequiredModelFiles(at directoryURL: URL, fileManager: FileManager) -> Bool {
        let configURL = directoryURL.appendingPathComponent("config.json")
        let tokenizerURL = directoryURL.appendingPathComponent("tokenizer.json")
        guard fileManager.fileExists(atPath: configURL.path),
              fileManager.fileExists(atPath: tokenizerURL.path)
        else {
            return false
        }
        guard let files = try? fileManager.contentsOfDirectory(atPath: directoryURL.path) else {
            return false
        }
        return files.contains { $0.hasSuffix(".safetensors") || $0 == "model.safetensors.index.json" }
    }

    private static func configJSON(at directoryURL: URL, fileManager: FileManager) -> [String: Any]? {
        let url = directoryURL.appendingPathComponent("config.json")
        guard let data = fileManager.contents(atPath: url.path),
              let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else {
            return nil
        }
        return object
    }

    private static func isVisionConfig(
        _ config: [String: Any],
        directoryURL: URL,
        fileManager: FileManager) -> Bool
    {
        if config["vision_config"] != nil || config["vision_config_dict"] != nil {
            return true
        }
        if let modelType = config["model_type"] as? String,
           modelType.localizedCaseInsensitiveContains("vl")
        {
            return true
        }
        let processorURL = directoryURL.appendingPathComponent("processor_config.json")
        return fileManager.fileExists(atPath: processorURL.path)
    }

    public static func defaultHomeDirectory() -> URL {
        URL(fileURLWithPath: NSHomeDirectory(), isDirectory: true)
    }
}

public struct JeevesMLXRuntimeConfiguration: Codable, Sendable, Equatable {
    public var isEnabled: Bool
    public var modelIdentifier: String?
    public var modelDirectoryURL: URL?
    public var allowsNetworkDownloads: Bool
    public var modelKind: JeevesMLXModelKind
    public var maxTokens: Int

    public init(
        isEnabled: Bool = false,
        modelIdentifier: String? = nil,
        modelDirectoryURL: URL? = nil,
        allowsNetworkDownloads: Bool = false,
        modelKind: JeevesMLXModelKind = .text,
        maxTokens: Int = 512)
    {
        self.isEnabled = isEnabled
        self.modelIdentifier = modelIdentifier
        self.modelDirectoryURL = modelDirectoryURL
        self.allowsNetworkDownloads = allowsNetworkDownloads
        self.modelKind = modelKind
        self.maxTokens = max(1, maxTokens)
    }

    public static func from(
        environment: [String: String],
        discoverInstalledModels: Bool = false,
        searchRoots: [URL] = JeevesMLXModelCatalog.defaultSearchRoots()) -> JeevesMLXRuntimeConfiguration
    {
        let explicitEnabled = Self.boolValue(environment["OPENJEEVES_MLX_ENABLED"])
        let explicitDirectory = Self.directoryURL(environment["OPENJEEVES_MLX_MODEL_DIR"])
        let explicitKind = Self.modelKind(environment["OPENJEEVES_MLX_MODEL_KIND"])
        let installed = discoverInstalledModels
            ? JeevesMLXModelCatalog.preferredInstalledModel(searchRoots: searchRoots)
            : nil
        let directory = explicitDirectory ?? installed?.directoryURL
        let detectedKind = directory.flatMap { JeevesMLXModelCatalog.modelKind(at: $0) }
        let modelKind = explicitKind ?? detectedKind ?? installed?.kind ?? .text

        return JeevesMLXRuntimeConfiguration(
            isEnabled: explicitEnabled ?? (directory != nil || installed != nil),
            modelIdentifier: Self.trimmed(environment["OPENJEEVES_MLX_MODEL_ID"]) ?? installed?.identifier,
            modelDirectoryURL: directory,
            allowsNetworkDownloads: Self.boolValue(environment["OPENJEEVES_MLX_ALLOW_DOWNLOADS"]) ?? false,
            modelKind: modelKind,
            maxTokens: Self.positiveInt(environment["OPENJEEVES_MLX_MAX_TOKENS"]) ?? 512)
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

    private static func modelKind(_ raw: String?) -> JeevesMLXModelKind? {
        guard let raw else { return nil }
        switch raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "llm", "text":
            return .text
        case "vlm", "vision", "multimodal":
            return .vision
        default:
            return nil
        }
    }

    private static func positiveInt(_ raw: String?) -> Int? {
        guard let raw, let value = Int(raw.trimmingCharacters(in: .whitespacesAndNewlines)), value > 0 else {
            return nil
        }
        return value
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
#if canImport(MLXLLM) && canImport(MLXLMCommon) && canImport(MLXHuggingFace) && canImport(Tokenizers)
        true
#else
        false
#endif
    }

    public static var isVisionModelSupportImportable: Bool {
#if canImport(MLXVLM) && canImport(MLXLMCommon) && canImport(MLXHuggingFace) && canImport(Tokenizers)
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
        visionModelSupportImportable: Bool = Self.isVisionModelSupportImportable,
        createDefaultRuntime: Bool = true,
        directoryExists: @escaping @Sendable (URL) -> Bool = { url in
            var isDirectory = ObjCBool(false)
            let exists = FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory)
            return exists && isDirectory.boolValue
        }) -> JeevesRuntimeCandidate
    {
        let defaultRuntime = runtime ?? (createDefaultRuntime ? self.defaultRuntime(configuration: configuration) : nil)
        let runtimeID = configuration.modelKind.runtimeID
        return JeevesRuntimeCandidate(
            id: runtimeID,
            displayName: configuration.modelKind.displayName,
            availability: {
                self.availability(
                    configuration: configuration,
                    runtime: defaultRuntime,
                    frameworkImportable: frameworkImportable,
                    languageModelSupportImportable: languageModelSupportImportable,
                    visionModelSupportImportable: visionModelSupportImportable,
                    directoryExists: directoryExists)
            },
            runtime: {
                guard let defaultRuntime else {
                    throw JeevesRuntimeRouterError.runtimeUnavailable(
                        runtimeID,
                        self.availability(
                            configuration: configuration,
                            runtime: defaultRuntime,
                            frameworkImportable: frameworkImportable,
                            languageModelSupportImportable: languageModelSupportImportable,
                            visionModelSupportImportable: visionModelSupportImportable,
                            directoryExists: directoryExists))
                }
                return defaultRuntime
            })
    }

    private static func availability(
        configuration: JeevesMLXRuntimeConfiguration,
        runtime: (any JeevesAgentRuntime)?,
        frameworkImportable: Bool,
        languageModelSupportImportable: Bool,
        visionModelSupportImportable: Bool,
        directoryExists: @Sendable (URL) -> Bool) -> JeevesRuntimeAvailability
    {
        guard configuration.isEnabled else {
            return .unavailable(.runtimeDisabled)
        }
        guard frameworkImportable else {
            return .unavailable(.frameworkUnavailable)
        }
        switch configuration.modelKind {
        case .text where !languageModelSupportImportable:
            return .unavailable(.frameworkUnavailable)
        case .vision where !visionModelSupportImportable:
            return .unavailable(.frameworkUnavailable)
        default:
            break
        }
        guard let modelDirectoryURL = configuration.modelDirectoryURL else {
            return .unavailable(.modelNotInstalled)
        }
        guard directoryExists(modelDirectoryURL) else {
            return .unavailable(.modelAssetMissing)
        }
        guard runtime != nil else {
            return .unavailable(.adapterUnavailable)
        }
        return .available
    }

    private static func defaultRuntime(configuration: JeevesMLXRuntimeConfiguration) -> (any JeevesAgentRuntime)? {
#if canImport(MLXLLM) && canImport(MLXVLM)
#if canImport(MLXLMCommon) && canImport(MLXHuggingFace)
#if canImport(Tokenizers)
        JeevesMLXRuntime(configuration: configuration)
#else
        nil
#endif
#else
        nil
#endif
#else
        nil
#endif
    }
}
