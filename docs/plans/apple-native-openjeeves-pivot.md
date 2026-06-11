---
title: Apple-Native OpenJeeves Pivot
type: roadmap
status: active
date: 2026-06-09
---

# Apple-Native OpenJeeves Pivot

Status: planning memo from repo and upstream inspection on 2026-06-09.

Implementation checkpoint on this branch:

- added `JeevesAgentCore` under `apps/shared/OpenClawKit` with sessions, turns, messages, runtime hints, events, and an in-memory runtime;
- added a native tool registry with a harmless runtime status tool as the first tool-contract foothold;
- added `JeevesFoundationModelsRuntime` as a separate SwiftPM product with Foundation Models availability mapping and deterministic prompt building;
- added `OpenJeevesNativeChatTransport`, an `OpenClawChatUI` transport backed by `JeevesAgentCore`;
- added a macOS feature flag (`OPENJEEVES_NATIVE_CHAT=1` or `openjeeves.nativeChat.enabled`) that routes chat windows, panels, and onboarding chat to the native transport;
- fixed the inherited Swift talk-config contract test helper so the shared Swift package has a clean test baseline;
- added focused Swift tests for the native core and Foundation Models adapter without requiring a live model response.

## Executive Direction

OpenJeeves should stop presenting itself as "OpenClaw plus Claude Code" and become a native Apple agent system. The existing repository is useful, but mostly as salvageable infrastructure:

- keep the Swift macOS/iOS app surfaces, shared Swift package, voice/wake work, pairing, permissions, and protocol-generation patterns;
- selectively harvest current OpenClaw upstream fixes for Apple app reliability and security;
- do not make OpenClaw's TypeScript gateway/provider stack the long-term center of the product;
- do not import or market around leaked Claude Code concepts;
- build the new agent loop in Swift around Foundation Models, Core AI, MLX, App Intents, and privacy-first Apple platform permissions.

The recommended path is a native-first line of work with a temporary compatibility bridge, not a full rebase of OpenJeeves onto current OpenClaw.

## Repository Facts

OpenJeeves current `origin/main`:

- Commit: `8a96f983360a5172bbfb4974b5dce913bf75cb85`
- Commit date: `2026-04-06T15:58:15-07:00`
- Package version: `2026.4.6`
- `package.json` still publishes as `openclaw`
- README says OpenJeeves is a branded OpenClaw fork enhanced with an open-source Claude Code leak
- Top-level Swift package `Swabble/` exists
- Native Apple code exists under `apps/macos`, `apps/ios`, and `apps/shared/OpenClawKit`

Current OpenClaw upstream `main` inspected:

- Commit: `c0a4a7890df400d2939886423275355688173854`
- Commit date as authored upstream: `2026-06-10T08:54:36+09:00`
- Package version: `2026.6.2`
- Tree diff against OpenJeeves: about 20,909 changed paths by name
- Approximate tree-level categories from OpenJeeves to upstream:
  - 8,913 added paths
  - 10,077 modified paths
  - 1,754 deleted paths
- Biggest changed areas: `src/agents`, `src/infra`, `src/gateway`, `src/commands`, `src/plugins`, `src/plugin-sdk`, `extensions/*`, `ui`, `apps/android`, `apps/macos`, `apps/ios`, and docs

This is too large to treat as a routine fork update.

## Important Upstream Drift

OpenClaw has moved Apple-related code since OpenJeeves forked:

- `Swabble/` moved under `apps/swabble/`.
- macOS now depends on `../swabble` rather than `../../Swabble`.
- upstream added `apps/macos-mlx-tts`, an isolated Swift helper package using `mlx-audio-swift`.
- upstream added `TalkMLXSpeechSynthesizer.swift`, `SpeechAudioBufferNormalizer.swift`, and talk-mode interruption support.
- upstream added substantial iOS design/runtime changes: Pro tabs, realtime talk sessions, permission prompts, WebRTC, Watch messaging updates, onboarding changes, and more tests.
- upstream added a clearer agent-runtime separation document: provider, model, runtime, and channel are different layers.
- upstream added a large `extensions/codex` runtime/plugin surface.

The Apple app work is worth reviewing and harvesting. The Codex runtime surface is not the desired OpenJeeves identity; at most, it is a useful example of how OpenClaw separates "model provider" from "agent runtime."

## Current Apple AI Surface

Primary-source review found these relevant Apple directions:

- Foundation Models framework: native Swift access to Apple Intelligence foundation models, with tool calling, guided generation/structured output, and provider-style extensibility.
- Private Cloud Compute support: Foundation Models has a server-side/PCC path in beta for enhanced capability while preserving Apple's privacy posture.
- Core AI: new Apple framework for running AI models on device through a modern Swift API, hardware specialization, and ahead-of-time compilation.
- Apple `coreai-models`: official model export recipes, Python primitives, and Swift runtime utilities; current requirements say macOS/iOS 27.0+ and Xcode 27.0+.
- MLX and MLX LM: Apple Silicon-oriented local model stack with Python, Swift, C++, and C APIs; best treated as Mac-first for large local LLMs and specialized local media/speech models.

Implication: OpenJeeves can be meaningfully native, but the runtime boundary must live in Swift. A TypeScript "provider" that shells out to Apple frameworks would keep the old architecture in charge.

## What To Keep

Keep and refactor:

- `apps/shared/OpenClawKit`: chat UI pieces, protocol types, device/node command models, permission-safe helpers.
- `apps/macos`: menu bar app, permissions, local automation, talk mode, push-to-talk, screen/canvas pieces, pairing and config UI.
- `apps/ios`: gateway/node pairing, device tools, camera/location/calendar/reminders/contacts/photos/watch surfaces, voice/talk work.
- `Swabble`/`apps/swabble`: wake-word and local speech pipeline work, but move toward the upstream location if we harvest OpenClaw changes.
- protocol-generation patterns from TypeScript to Swift, only while the compatibility gateway exists.
- security posture around pairing, host execution approvals, sandboxing, allowlists, and untrusted inbound messages.
- upstream's MLX TTS helper as a reference or cherry-pick candidate, not as the final LLM runtime.

Keep temporarily:

- the TypeScript gateway as `OpenClawCompatibilityBridge` or similar, for existing channel integrations and migration tests.
- provider catalog/config ideas only where they help bridge existing users.

## What To Remove Or Reframe

Remove from public identity:

- "powered by Claude Code & OpenClaw"
- "leaked source code"
- "branded fork"
- OpenClaw package/repository metadata where OpenJeeves is the product
- OpenClaw config paths as the canonical user-facing path

Avoid bringing forward as product direction:

- Codex/Claude CLI as the main agent system
- broad multi-provider cloud catalog as the primary value prop
- channel sprawl before the native macOS/iOS experience works
- manager-of-manager agent hierarchies copied from prompt bundles
- TypeScript-first runtime ownership for Apple-native model calls

## Recommended Architecture

Create a native Swift core:

```text
JeevesKit
  JeevesAgentCore
    AgentRuntime protocol
    AgentSession / AgentTurn / AgentMessage
    ToolRegistry
    PermissionBroker
    MemoryStore
    EventLog
  JeevesFoundationModelsRuntime
    System language model
    tool calling
    guided generation
    PCC/cloud escalation when available and allowed
  JeevesCoreAIRuntime
    .aimodel loading
    model specialization/cache control
    local model metadata and benchmarks
  JeevesMLXRuntime
    macOS-only local LLM/media helpers
    process isolation for heavy dependencies
  JeevesPlatformTools
    App Intents
    Shortcuts-facing actions
    macOS automation with explicit approvals
    iOS device tools with entitlement-aware limits
```

Runtime selection should be explicit:

- `foundationModels`: default on supported Apple Intelligence devices.
- `foundationModelsCloud`: opt-in or automatic escalation through Foundation Models/PCC when available and permitted.
- `coreAI`: packaged or downloaded `.aimodel` assets.
- `mlx`: Mac-only local model helper/runtime for models that are impractical through Foundation Models or Core AI.
- `compatibilityBridge`: temporary OpenClaw gateway route.

The system should choose the most private and local viable runtime first, then escalate only when a user policy allows it.

## Migration Strategy

### Phase 0: Stop The Clone Story

- Rewrite README and docs around the Apple-native direction.
- Mark OpenClaw gateway as legacy compatibility infrastructure.
- Remove leaked-Claude language.
- Decide public package/app names and bundle IDs before changing code broadly.

### Phase 1: Create The Native Runtime Skeleton

- Add `JeevesAgentCore` as a Swift package or target under `apps/shared`.
- Define the runtime protocol and event model.
- Add a local in-memory session loop and tests.
- Add a small tool registry with one harmless tool, such as app status or date/time.
- Wire macOS and iOS chat UI to the native runtime behind a feature flag.

### Phase 2: Foundation Models First

- Add a Foundation Models runtime target with availability guards.
- Implement structured response generation and a minimal tool-calling bridge.
- Add runtime diagnostics: supported/unavailable/requires Apple Intelligence/network/PCC.
- Add tests that compile without requiring model availability on CI.

### Phase 3: Core AI And MLX

- Add Core AI as an optional runtime target for OS/Xcode 27+.
- Start with Apple `coreai-models` sample assets and runtime utilities.
- Keep MLX in a separate helper process/package on macOS, following upstream's isolated `apps/macos-mlx-tts` pattern.
- Use MLX for local specialist models, speech/media, and Mac-only larger LLM experiments.

### Phase 4: Platform Tools And App Intents

- Convert selected device/gateway commands into native tools.
- Add App Intents/Shortcuts surfaces for user-approved actions.
- Build a native permissions dashboard.
- Keep all high-risk tools behind explicit approval policies.

### Phase 5: Retire Or Narrow The OpenClaw Bridge

- Decide which channels matter for OpenJeeves.
- Keep the bridge only for channels that have no near-term native equivalent.
- Stop syncing upstream wholesale once the native runtime owns the product path.

## Upstream Harvest Candidates

Review/cherry-pick selectively:

- `apps/swabble` relocation and package path updates.
- `apps/macos-mlx-tts` helper and `TalkMLXSpeechSynthesizer.swift`.
- macOS packaging and dependency pin updates.
- iOS realtime talk/WebRTC work if it aligns with OpenJeeves UX.
- iOS permission/onboarding improvements.
- OpenClaw's agent-runtime documentation model as a reference for OpenJeeves runtime docs.
- security fixes in pairing, gateway exposure, exec approvals, and host environment sanitization.

Avoid wholesale import:

- `extensions/codex` as OpenJeeves's agent identity.
- broad upstream provider/channel catalog unless needed for a compatibility release.
- upstream branding/docs/appcast metadata.

## Decision

Do not rebase OpenJeeves onto current OpenClaw as the main strategy.

Recommended path:

1. Start a native `JeevesKit`/`JeevesAgentCore` line inside this repo.
2. Harvest targeted upstream Apple app and security improvements.
3. Keep the OpenClaw gateway only as a bridge while native runtimes mature.
4. Make Foundation Models the first real runtime.
5. Add Core AI and MLX as separate optional runtimes with clear OS/device constraints.

This gives OpenJeeves a real reason to exist: a private, Apple-native agent system that can use Apple's system models, local custom models, and Apple Silicon acceleration directly from macOS and iOS.
