---
summary: "OpenJeeves is a native Apple agent system for macOS and iOS."
read_when:
  - Introducing OpenJeeves to newcomers
title: "OpenJeeves"
---

# OpenJeeves

<p align="center">
    <img
        src="/assets/openjeeves-logo-text.svg"
        alt="OpenJeeves"
        width="500"
        class="dark:hidden"
    />
    <img
        src="/assets/openjeeves-logo-text-light.svg"
        alt="OpenJeeves"
        width="500"
        class="hidden dark:block"
    />
</p>

<p align="center">
  <strong>A native Apple agent system for macOS and iOS.</strong><br />
  OpenJeeves is moving toward Swift-native Foundation Models, Core AI, MLX, App Intents, and local-first Apple platform automation.
</p>

<Columns>
  <Card title="Getting Started" href="/getting-started" icon="rocket">
    Run the current compatibility bridge or start native Apple development.
  </Card>
  <Card title="Apple-Native Pivot" href="/plans/apple-native-openjeeves-pivot" icon="map">
    Read the repo-grounded migration plan and upstream comparison.
  </Card>
  <Card title="Security" href="/security" icon="shield">
    Review the inherited security posture while native approvals are built.
  </Card>
</Columns>

## What Is OpenJeeves?

OpenJeeves is being rebuilt as a personal Apple agent that runs close to the user: on the Mac, iPhone, iPad, and eventually watch surfaces. The goal is a native assistant that can understand requests, call local tools, respect permissions, and use Apple-provided and Apple-Silicon-optimized models.

The repository still contains inherited gateway infrastructure. That compatibility bridge is useful while the native runtime is under construction, but it is not the final product architecture.

## Target Runtime Stack

<Columns>
  <Card title="Foundation Models" icon="sparkles">
    First runtime target for Apple Intelligence language capability, structured output, and tool calling.
  </Card>
  <Card title="Core AI" icon="cpu">
    Future runtime for compiled on-device model assets as toolchain and OS availability allow.
  </Card>
  <Card title="MLX" icon="hard-drive">
    Mac-first Apple Silicon path for local specialist models and heavier local helpers.
  </Card>
  <Card title="App Intents" icon="workflow">
    Native user-approved automation exposed to Shortcuts and system surfaces.
  </Card>
</Columns>

## Current Code To Reuse

<Columns>
  <Card title="macOS App" icon="monitor">
    Menu bar app, permissions, talk mode, push-to-talk, canvas, gateway control, and local automation.
  </Card>
  <Card title="iOS App" icon="smartphone">
    Pairing, camera, location, contacts, calendar, reminders, photos, voice, watch, and share surfaces.
  </Card>
  <Card title="Shared Swift" icon="package">
    Chat UI, protocol models, device commands, and support utilities in shared Swift packages.
  </Card>
  <Card title="Compatibility Bridge" icon="cable">
    Existing gateway and channel code while native OpenJeeves catches up.
  </Card>
</Columns>

## Current Developer Path

Run the compatibility bridge when you need inherited behavior:

```bash
pnpm install
pnpm ui:build
pnpm build
pnpm openclaw gateway run --bind loopback --port 18789
```

Work on native app surfaces here:

- `apps/macos`
- `apps/ios`
- `apps/shared/OpenClawKit`
- `Swabble`

## Start Here

<Columns>
  <Card title="Getting Started" href="/getting-started" icon="book-open">
    Current compatibility and native development paths.
  </Card>
  <Card title="Pivot Plan" href="/plans/apple-native-openjeeves-pivot" icon="map">
    What to keep, what to remove, and how to migrate.
  </Card>
  <Card title="Configuration" href="/configuration" icon="settings">
    Current inherited configuration while native config is designed.
  </Card>
  <Card title="Security" href="/security" icon="shield">
    Pairing, permissions, and safe defaults.
  </Card>
</Columns>
