# Getting Started with OpenJeeves

OpenJeeves is being rebuilt as a native macOS/iOS agent system. The current repository still includes an inherited gateway compatibility path, but the product direction is Swift-native: Foundation Models first, then Core AI and MLX where they fit.

## Choose A Path

Use the compatibility gateway when you need the existing web UI, protocol, or channel bridge today. Use the native development path when working on the new OpenJeeves runtime.

## Compatibility Gateway

Prerequisites:

- Node.js 22+; Node 24 recommended.
- pnpm, npm, or bun.

Run the inherited gateway:

```bash
git clone https://github.com/noktirnal42/openjeeves.git
cd openjeeves
pnpm install
pnpm ui:build
pnpm build
pnpm openclaw gateway run --bind loopback --port 18789
```

Open the local control UI:

```text
http://localhost:18789
```

Compatibility config still lives at the inherited OpenClaw path:

```text
~/.openclaw/openclaw.json
```

That path will change or be wrapped once OpenJeeves has a native configuration layer.

## Native Apple Development

The native app surfaces live here:

- `apps/macos`
- `apps/ios`
- `apps/shared/OpenClawKit`
- `Swabble`

Current native run scripts still use inherited names:

```bash
pnpm mac:restart
pnpm ios:build
pnpm ios:run
```

The next implementation target is a Swift runtime skeleton that can be called from macOS and iOS without routing every turn through the TypeScript gateway.

## Runtime Direction

OpenJeeves should grow these runtimes in order:

1. `foundationModels`: Apple Foundation Models on supported devices.
2. `foundationModelsCloud`: Apple cloud/PCC escalation when available and allowed.
3. `coreAI`: compiled on-device model assets.
4. `mlx`: Mac-first local model helpers for Apple Silicon.
5. `compatibilityBridge`: inherited gateway route for transitional workflows.

## Existing Useful Surfaces

- macOS: menu bar app, permissions, talk mode, gateway control, push-to-talk, canvas, and local automation.
- iOS: pairing, device tools, camera, location, contacts, calendars, reminders, photos, watch, voice, and share extension.
- Shared Swift: chat UI, protocol models, device command types, and support utilities.
- Speech: local wake and speech work that should be reconciled with current upstream `apps/swabble`.

## Next Steps

- Read the [Apple-native pivot plan](plans/apple-native-openjeeves-pivot.md).
- Read the [Vision](../VISION.md).
- Use the compatibility gateway only when you need current inherited behavior.
- Start new model/runtime work in Swift, not as another TypeScript provider bolted onto the gateway.
