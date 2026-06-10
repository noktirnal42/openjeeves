import JeevesAgentCore
@testable import JeevesFoundationModelsRuntime
import Testing

struct JeevesFoundationModelsRuntimeTests {
    @Test
    func promptBuilderKeepsRecentHistoryInTurnOrder() {
        let builder = JeevesFoundationModelsPromptBuilder(maxHistoryMessages: 2)
        let turn = JeevesAgentTurn(
            sessionID: "session-1",
            input: JeevesAgentMessage(role: .user, content: "What next?"),
            history: [
                JeevesAgentMessage(role: .system, content: "Be concise."),
                JeevesAgentMessage(role: .user, content: "Start the pivot."),
                JeevesAgentMessage(role: .assistant, content: "Create the core runtime."),
            ])

        let prompt = builder.prompt(for: turn)

        #expect(prompt == """
        Conversation so far:
        User: Start the pivot.
        Assistant: Create the core runtime.

        User: What next?
        Assistant:
        """)
    }

    @Test
    func promptBuilderCanOmitHistory() {
        let builder = JeevesFoundationModelsPromptBuilder(maxHistoryMessages: 0)
        let turn = JeevesAgentTurn(
            sessionID: "session-1",
            input: JeevesAgentMessage(role: .user, content: "  Local only, please.  "),
            history: [
                JeevesAgentMessage(role: .assistant, content: "Ignored"),
            ])

        let prompt = builder.prompt(for: turn)

        #expect(prompt == """
        User: Local only, please.
        Assistant:
        """)
    }

    @Test
    func availabilityStatusLabelsAreStable() {
        #expect(JeevesFoundationModelsAvailability.available.isAvailable)
        #expect(JeevesFoundationModelsAvailability.available.statusLabel == "available")
        #expect(!JeevesFoundationModelsAvailability.unavailable(.modelNotReady).isAvailable)
        #expect(JeevesFoundationModelsAvailability.unavailable(.modelNotReady).statusLabel == "modelNotReady")
    }

    @Test
    func currentAvailabilityReturnsConcreteState() {
        let availability = JeevesFoundationModelsSupport.currentAvailability()

        #expect(!availability.statusLabel.isEmpty)
    }
}
