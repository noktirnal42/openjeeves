# OpenJeeves Vision

OpenJeeves is a native Apple agent system for people who want a capable personal assistant that feels local, private, and deeply integrated with macOS and iOS.

The long-term product is not a generic gateway clone. It is a Swift-native agent runtime that can use Apple platform intelligence directly:

- Foundation Models for system-provided language intelligence, structured output, and tool calling.
- Core AI for compiled on-device model assets as Apple opens that stack.
- MLX for Apple Silicon local models and specialist Mac-first helpers.
- App Intents and Shortcuts for user-approved automation.
- SwiftUI apps for macOS, iOS, watchOS, and shared Apple device surfaces.

## Product Principles

OpenJeeves should feel like an Apple-native assistant, not a web service wrapped in a menu bar.

- Local first: prefer on-device execution and local context whenever possible.
- Permission honest: every powerful action should have a clear user-controlled approval path.
- Native by default: Swift, SwiftUI, App Intents, Foundation Models, Core AI, and Apple platform APIs should own the main experience.
- Compatibility is temporary: inherited gateway code can bridge existing features, but it should not define the final architecture.
- Useful before broad: nail the macOS/iOS daily assistant loop before chasing every channel and provider.
- Security is product quality: pairing, sandboxing, allowlists, logs, and approval trails are part of the UX.

## Near-Term Focus

Priority:

- Replace public clone/Claude/OpenClaw positioning with the Apple-native direction.
- Build a small native Swift agent runtime skeleton.
- Connect one macOS/iOS chat path to the native runtime behind a feature flag.
- Implement a minimal Foundation Models runtime with availability diagnostics.
- Preserve existing app and protocol work that helps the native path.

Next priorities:

- Add a native tool registry around App Intents and existing device capabilities.
- Move wake/speech work toward the newer `apps/swabble` layout from current upstream OpenClaw.
- Evaluate upstream MLX speech helpers for targeted harvest.
- Add Core AI experiments once local toolchain and OS availability support it.
- Define when the compatibility gateway is required, optional, or retired.

## What We Will Not Optimize For

- Being a branded OpenClaw fork.
- Being an external coding CLI wrapper.
- Matching OpenClaw's full provider and channel catalog.
- Making TypeScript the owner of Apple-native model execution.
- Shipping broad agent hierarchies before the core local assistant loop works.
- Hiding risky automation behind convenience.

## Architecture Direction

OpenJeeves should split model selection from runtime ownership:

- `foundationModels`: default Apple Intelligence path on supported devices.
- `foundationModelsCloud`: Apple cloud/PCC escalation when available and allowed.
- `coreAI`: compiled on-device model assets.
- `mlx`: Mac-first local model helpers.
- `compatibilityBridge`: inherited gateway path for transitional workflows.

The Swift runtime should own sessions, tool calls, permissions, memory, and event logs. The compatibility bridge can remain useful, but it should become one integration behind the native product rather than the product itself.

## Migration Guardrail

Do not rebase OpenJeeves wholesale onto current OpenClaw as the main strategy. The fork is too stale and the desired product direction is different.

Use OpenClaw upstream as a source of targeted fixes:

- Apple app reliability.
- iOS and macOS onboarding.
- MLX speech and local audio experiments.
- pairing, gateway exposure, and execution-approval security.
- protocol lessons that help the temporary bridge.

Then continue building the native OpenJeeves line in Swift.
