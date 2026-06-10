import Foundation
import OpenClawChatUI
import OpenClawKit
import Testing
@testable import OpenClaw

@Suite struct OpenJeevesNativeChatFeatureTests {
    @Test func defaultsToGatewayModeWhenUnset() {
        let defaults = Self.makeDefaults()

        #expect(!OpenJeevesNativeChatFeature.isEnabled(environment: [:], defaults: defaults))
    }

    @Test func environmentValueWinsOverDefaults() {
        let defaults = Self.makeDefaults()
        defaults.set(true, forKey: "openjeeves.nativeChat.enabled")

        #expect(!OpenJeevesNativeChatFeature.isEnabled(
            environment: ["OPENJEEVES_NATIVE_CHAT": "false"],
            defaults: defaults))
        #expect(OpenJeevesNativeChatFeature.isEnabled(
            environment: ["OPENJEEVES_NATIVE_CHAT": "yes"],
            defaults: defaults))
    }

    @Test func invalidEnvironmentValueDisablesNativeMode() {
        let defaults = Self.makeDefaults()
        defaults.set(true, forKey: "openjeeves.nativeChat.enabled")

        #expect(!OpenJeevesNativeChatFeature.isEnabled(
            environment: ["OPENJEEVES_NATIVE_CHAT": "maybe"],
            defaults: defaults))
    }

    @Test func transportFactoryUsesGatewayByDefault() {
        let transport = OpenJeevesNativeChatFeature.makeTransport(
            gateway: GatewayNodeSession(),
            environment: [:],
            defaults: Self.makeDefaults())

        #expect(transport is IOSGatewayChatTransport)
    }

    @Test func transportFactoryUsesNativeTransportWhenEnabled() {
        let transport = OpenJeevesNativeChatFeature.makeTransport(
            gateway: GatewayNodeSession(),
            environment: ["OPENJEEVES_NATIVE_CHAT": "true"],
            defaults: Self.makeDefaults())

        #expect(transport is OpenJeevesNativeChatTransport)
    }

    private static func makeDefaults() -> UserDefaults {
        let suiteName = "OpenJeevesNativeChatFeatureTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }
}
