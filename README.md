# OpenJeeves

<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="docs/assets/openjeeves-logo-text-light.svg">
    <img src="docs/assets/openjeeves-logo-text.svg" alt="OpenJeeves" width="500">
  </picture>
</p>

<p align="center">
  <strong>A native Apple agent system for macOS and iOS.</strong>
</p>

<p align="center">
  <a href="https://github.com/noktirnal42/openjeeves/actions/workflows/ci.yml?branch=main"><img src="https://img.shields.io/github/actions/workflow/status/noktirnal42/openjeeves/ci.yml?branch=main&style=for-the-badge" alt="CI status"></a>
  <a href="https://github.com/noktirnal42/openjeeves/releases"><img src="https://img.shields.io/github/v/release/noktirnal42/openjeeves?include_prereleases&style=for-the-badge" alt="GitHub release"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-blue.svg?style=for-the-badge" alt="MIT License"></a>
</p>

OpenJeeves is being rebuilt as a privacy-first personal agent for Apple devices. The target product is a Swift-native macOS/iOS system that can use Apple's Foundation Models, Core AI, App Intents, and Apple Silicon local-model runtimes through MLX.

This repository still contains compatibility infrastructure inherited from OpenClaw. That code is useful for protocol, pairing, messaging, security, and app scaffolding, but it is no longer the product direction. OpenJeeves should define itself by the native Apple runtime, not by inherited gateway code or external coding CLI wrappers.

## Current Status

OpenJeeves is in a transition state.

- The existing macOS, iOS, watch, and shared Swift packages are the foundation for the native product.
- The TypeScript gateway remains available as a compatibility bridge while the Swift agent runtime is built.
- Public docs are being rewritten around the Apple-native direction.
- The implementation plan lives in [docs/plans/apple-native-openjeeves-pivot.md](docs/plans/apple-native-openjeeves-pivot.md).

## Target Architecture

The native OpenJeeves line will center on Swift packages and Apple platform capabilities:

- `JeevesAgentCore`: sessions, turns, messages, tools, permissions, memory, and event logging.
- `JeevesFoundationModelsRuntime`: Apple Foundation Models for local system intelligence, tool calling, guided generation, and optional Apple cloud/PCC escalation when available and allowed.
- `JeevesCoreAIRuntime`: Core AI model loading, specialization, and on-device execution for supported Apple model assets.
- `JeevesMLXRuntime`: Mac-first local model helpers for larger or specialist models that make sense on Apple Silicon.
- `JeevesPlatformTools`: App Intents, Shortcuts-facing actions, macOS automation, and iOS device tools behind explicit permission policies.

Runtime selection should prefer the most private viable local runtime first, then escalate only when the user has allowed it.

## What Exists Today

Useful pieces already in the repository:

- `apps/macos`: macOS menu bar app, local permissions, talk mode, gateway control, push-to-talk, canvas, and host automation surfaces.
- `apps/ios`: iOS node app, pairing, camera, location, contacts, calendars, reminders, photos, watch, voice, and share extension surfaces.
- `apps/shared/OpenClawKit`: shared Swift UI, protocol, device command, and support utilities that can become OpenJeeves shared infrastructure.
- `Swabble`: Swift speech and wake-word utilities that should be reconciled with upstream's newer `apps/swabble` layout.
- `src`, `extensions`, `ui`, and gateway docs: compatibility infrastructure that should be narrowed over time instead of treated as the long-term product center.

## Development Priorities

1. Stop the clone story in public docs and product metadata.
2. Add a native Swift agent runtime skeleton under the Apple app/shared package structure.
3. Wire macOS and iOS chat surfaces to the native runtime behind a feature flag.
4. Implement Foundation Models as the first real runtime.
5. Add Core AI and MLX as optional runtimes with clear OS, Xcode, and device constraints.
6. Harvest targeted upstream OpenClaw fixes for Apple app reliability, MLX speech, packaging, security, and pairing.
7. Shrink the OpenClaw compatibility bridge as native OpenJeeves features replace it.

## Compatibility Gateway

For now, the inherited gateway can still be run for compatibility work:

```bash
pnpm install
pnpm ui:build
pnpm build
pnpm openclaw gateway run --bind loopback --port 18789
```

This command path is not the desired final user experience. It exists so the current app, protocol, and channel code can keep working while the native Swift runtime comes online.

## Documentation

- [Getting Started](docs/getting-started.md)
- [Apple-native pivot plan](docs/plans/apple-native-openjeeves-pivot.md)
- [Vision](VISION.md)
- [Configuration](docs/configuration.md)
- [Security](docs/security.md)

## License

OpenJeeves is MIT licensed. See [LICENSE](LICENSE).
