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
        [
            OpenClawChatModelChoice(
                modelID: self.runtime.id.rawValue,
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
        let trimmed = message.trimmingCharacters(in: .whitespacesAndNewlines)
        let inputText = trimmed.isEmpty && !attachments.isEmpty ? "See attached." : trimmed
        let input = JeevesAgentMessage(
            role: .user,
            content: inputText,
            metadata: [
                "attachments.count": String(attachments.count),
                "source": "openclaw-chat-ui",
            ])

        do {
            _ = try await session.run(
                input: input,
                runtime: self.runtime,
                hints: JeevesRuntimeHints(preferredRuntime: self.runtime.id))
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
        let sessions = await self.state.sessionEntries(limit: limit, runtimeID: self.runtime.id)
        return OpenClawChatSessionsListResponse(
            ts: Date().timeIntervalSince1970 * 1000,
            path: nil,
            count: sessions.count,
            defaults: OpenClawChatSessionsDefaults(
                model: "openjeeves/\(self.runtime.id.rawValue)",
                contextTokens: nil,
                mainSessionKey: "main"),
            sessions: sessions)
    }

    public func setSessionModel(sessionKey _: String, model _: String?) async throws {}

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
        case .compatibilityBridge:
            "Compatibility Bridge"
        case .inMemory:
            "Native In-Memory"
        }
    }

    private static func chatPayload(from message: JeevesAgentMessage) -> AnyCodable {
        AnyCodable([
            "role": AnyCodable(message.role.rawValue),
            "content": AnyCodable([
                [
                    "type": "text",
                    "text": message.content,
                ],
            ]),
        ])
    }
}

private actor OpenJeevesNativeChatTransportState {
    private var activeSessionKey = "main"
    private var sessions: [String: JeevesAgentSession] = [:]
    private var updatedAtBySession: [String: Double] = [:]

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

    func sessionEntries(limit: Int?, runtimeID: JeevesRuntimeID) -> [OpenClawChatSessionEntry] {
        _ = self.session(for: self.activeSessionKey)
        let entries = self.sessions.keys.map { key in
            OpenClawChatSessionEntry(
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
                model: runtimeID.rawValue,
                contextTokens: nil)
        }
        let sorted = entries.sorted { ($0.updatedAt ?? 0) > ($1.updatedAt ?? 0) }
        guard let limit, limit >= 0 else { return sorted }
        return Array(sorted.prefix(limit))
    }
}
