import Foundation
import JeevesAgentCore
import OpenClawKit

public final class OpenJeevesNativeChatTransport: @unchecked Sendable, OpenClawChatTransport {
    private let state = OpenJeevesNativeChatTransportState()
    private let runtime: any JeevesAgentRuntime
    private let stream: AsyncStream<OpenClawChatTransportEvent>
    private let continuation: AsyncStream<OpenClawChatTransportEvent>.Continuation

    public init(runtime: any JeevesAgentRuntime = JeevesInMemoryAgentRuntime()) {
        self.runtime = runtime
        var continuation: AsyncStream<OpenClawChatTransportEvent>.Continuation!
        self.stream = AsyncStream { streamContinuation in
            continuation = streamContinuation
        }
        self.continuation = continuation
    }

    public func setActiveSessionKey(_ sessionKey: String) async throws {
        await self.state.setActiveSessionKey(Self.normalizedSessionKey(sessionKey))
    }

    public func requestHistory(sessionKey: String) async throws -> OpenClawChatHistoryPayload {
        let key = Self.normalizedSessionKey(sessionKey)
        let session = await self.state.session(for: key)
        let messages = await session.history()
        return OpenClawChatHistoryPayload(
            sessionKey: key,
            sessionId: key,
            messages: messages.map(Self.chatPayload(from:)),
            thinkingLevel: "off")
    }

    public func listModels() async throws -> [OpenClawChatModelChoice] {
        if let router = self.runtime as? JeevesRuntimeRouter {
            return await router.choices().map { choice in
                OpenClawChatModelChoice(
                    modelID: Self.modelID(for: choice.id),
                    name: Self.modelName(for: choice),
                    provider: "openjeeves",
                    contextWindow: nil)
            }
        }

        return [
            OpenClawChatModelChoice(
                modelID: Self.modelID(for: self.runtime.id),
                name: Self.modelName(for: self.runtime.id),
                provider: "openjeeves",
                contextWindow: nil),
        ]
    }

    public func sendMessage(
        sessionKey: String,
        message: String,
        thinking _: String,
        idempotencyKey: String,
        attachments: [OpenClawChatAttachmentPayload]) async throws -> OpenClawChatSendResponse
    {
        let key = Self.normalizedSessionKey(sessionKey)
        let session = await self.state.session(for: key)
        let configuredRuntime = await self.state.preferredRuntime(for: key) ?? self.runtime.id
        let preferredRuntime = attachments.contains(where: Self.isImageAttachment) ? .mlxVLM : configuredRuntime
        let trimmed = message.trimmingCharacters(in: .whitespacesAndNewlines)
        let inputText = trimmed.isEmpty && !attachments.isEmpty ? "See attached." : trimmed
        let input = JeevesAgentMessage(
            role: .user,
            content: inputText,
            metadata: [
                "attachments.count": String(attachments.count),
                "source": "openclaw-chat-ui",
            ],
            attachments: attachments.compactMap(Self.agentAttachment(from:)))

        do {
            _ = try await session.run(
                input: input,
                runtime: self.runtime,
                hints: JeevesRuntimeHints(preferredRuntime: preferredRuntime))
            await self.state.markUpdated(sessionKey: key)
            self.continuation.yield(.chat(OpenClawChatEventPayload(
                runId: idempotencyKey,
                sessionKey: key,
                state: "final",
                message: nil,
                errorMessage: nil)))
            return OpenClawChatSendResponse(runId: idempotencyKey, status: "ok")
        } catch {
            self.continuation.yield(.chat(OpenClawChatEventPayload(
                runId: idempotencyKey,
                sessionKey: key,
                state: "error",
                message: nil,
                errorMessage: error.localizedDescription)))
            throw error
        }
    }

    public func abortRun(sessionKey: String, runId: String) async throws {
        self.continuation.yield(.chat(OpenClawChatEventPayload(
            runId: runId,
            sessionKey: Self.normalizedSessionKey(sessionKey),
            state: "aborted",
            message: nil,
            errorMessage: nil)))
    }

    public func listSessions(limit: Int?) async throws -> OpenClawChatSessionsListResponse {
        let sessions = await self.state.sessionEntries(limit: limit, defaultRuntimeID: self.runtime.id)
        return OpenClawChatSessionsListResponse(
            ts: Date().timeIntervalSince1970 * 1000,
            path: nil,
            count: sessions.count,
            defaults: OpenClawChatSessionsDefaults(
                model: Self.modelID(for: self.runtime.id),
                contextTokens: nil,
                mainSessionKey: "main"),
            sessions: sessions)
    }

    public func setSessionModel(sessionKey: String, model: String?) async throws {
        await self.state.setPreferredRuntime(
            Self.runtimeID(from: model),
            sessionKey: Self.normalizedSessionKey(sessionKey))
    }

    public func setSessionThinking(sessionKey _: String, thinkingLevel _: String) async throws {}

    public func requestHealth(timeoutMs _: Int) async throws -> Bool {
        true
    }

    public func events() -> AsyncStream<OpenClawChatTransportEvent> {
        self.stream
    }

    public func resetSession(sessionKey: String) async throws {
        await self.state.reset(sessionKey: Self.normalizedSessionKey(sessionKey))
    }

    public func compactSession(sessionKey _: String) async throws {}

    private static func normalizedSessionKey(_ raw: String) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "main" : trimmed
    }

    fileprivate static func modelID(for id: JeevesRuntimeID) -> String {
        "openjeeves/\(id.rawValue)"
    }

    private static func runtimeID(from model: String?) -> JeevesRuntimeID? {
        guard let model else { return nil }
        let trimmed = model.trimmingCharacters(in: .whitespacesAndNewlines)
        let raw = trimmed.hasPrefix("openjeeves/")
            ? String(trimmed.dropFirst("openjeeves/".count))
            : trimmed
        return JeevesRuntimeID(rawValue: raw)
    }

    private static func modelName(for id: JeevesRuntimeID) -> String {
        switch id {
        case .foundationModels:
            "Foundation Models"
        case .foundationModelsCloud:
            "Foundation Models Cloud"
        case .coreAI:
            "Core AI"
        case .mlx:
            "MLX"
        case .mlxVLM:
            "MLX VLM"
        case .compatibilityBridge:
            "Compatibility Bridge"
        case .inMemory:
            "Native In-Memory"
        }
    }

    private static func modelName(for choice: JeevesRuntimeRouteChoice) -> String {
        let base = self.modelName(for: choice.id)
        guard choice.availability != .available else { return base }
        return "\(base) (\(choice.availability.statusLabel))"
    }

    private static func chatPayload(from message: JeevesAgentMessage) -> AnyCodable {
        var content = [
            AnyCodable([
                "type": AnyCodable("text"),
                "text": AnyCodable(message.content),
            ]),
        ]
        for attachment in message.attachments {
            content.append(AnyCodable([
                "type": AnyCodable(attachment.type),
                "mimeType": AnyCodable(attachment.mimeType),
                "fileName": AnyCodable(attachment.fileName),
                "content": AnyCodable(attachment.data.base64EncodedString()),
            ]))
        }
        return AnyCodable([
            "role": AnyCodable(message.role.rawValue),
            "content": AnyCodable(content),
        ])
    }

    private static func agentAttachment(from payload: OpenClawChatAttachmentPayload) -> JeevesAgentAttachment? {
        guard let data = Data(base64Encoded: payload.content) else { return nil }
        return JeevesAgentAttachment(
            type: payload.type,
            mimeType: payload.mimeType,
            fileName: payload.fileName,
            data: data)
    }

    private static func isImageAttachment(_ payload: OpenClawChatAttachmentPayload) -> Bool {
        payload.mimeType.lowercased().hasPrefix("image/")
    }
}

private actor OpenJeevesNativeChatTransportState {
    private var activeSessionKey = "main"
    private var sessions: [String: JeevesAgentSession] = [:]
    private var updatedAtBySession: [String: Double] = [:]
    private var preferredRuntimeBySession: [String: JeevesRuntimeID] = [:]

    func setActiveSessionKey(_ sessionKey: String) {
        self.activeSessionKey = sessionKey
        _ = self.session(for: sessionKey)
    }

    func session(for sessionKey: String) -> JeevesAgentSession {
        if let session = self.sessions[sessionKey] {
            return session
        }
        let session = JeevesAgentSession(id: sessionKey)
        self.sessions[sessionKey] = session
        self.updatedAtBySession[sessionKey] = Date().timeIntervalSince1970 * 1000
        return session
    }

    func markUpdated(sessionKey: String) {
        _ = self.session(for: sessionKey)
        self.updatedAtBySession[sessionKey] = Date().timeIntervalSince1970 * 1000
    }

    func reset(sessionKey: String) {
        self.sessions[sessionKey] = JeevesAgentSession(id: sessionKey)
        self.updatedAtBySession[sessionKey] = Date().timeIntervalSince1970 * 1000
    }

    func setPreferredRuntime(_ runtimeID: JeevesRuntimeID?, sessionKey: String) {
        _ = self.session(for: sessionKey)
        self.preferredRuntimeBySession[sessionKey] = runtimeID
        self.updatedAtBySession[sessionKey] = Date().timeIntervalSince1970 * 1000
    }

    func preferredRuntime(for sessionKey: String) -> JeevesRuntimeID? {
        self.preferredRuntimeBySession[sessionKey]
    }

    func sessionEntries(limit: Int?, defaultRuntimeID: JeevesRuntimeID) -> [OpenClawChatSessionEntry] {
        _ = self.session(for: self.activeSessionKey)
        let entries = self.sessions.keys.map { key in
            let runtimeID = self.preferredRuntimeBySession[key] ?? defaultRuntimeID
            return OpenClawChatSessionEntry(
                key: key,
                kind: "native",
                displayName: key == "main" ? "Native Main" : key,
                surface: "openjeeves-native",
                subject: nil,
                room: nil,
                space: nil,
                updatedAt: self.updatedAtBySession[key],
                sessionId: key,
                systemSent: nil,
                abortedLastRun: nil,
                thinkingLevel: "off",
                verboseLevel: nil,
                inputTokens: nil,
                outputTokens: nil,
                totalTokens: nil,
                modelProvider: "openjeeves",
                model: OpenJeevesNativeChatTransport.modelID(for: runtimeID),
                contextTokens: nil)
        }
        let sorted = entries.sorted { ($0.updatedAt ?? 0) > ($1.updatedAt ?? 0) }
        guard let limit, limit >= 0 else { return sorted }
        return Array(sorted.prefix(limit))
    }
}
