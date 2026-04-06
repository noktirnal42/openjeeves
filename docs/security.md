# Security

Security guidance for deploying OpenJeeves.

## Overview

OpenJeeves connects to real messaging surfaces and executes tools on your behalf. Treat it like any other privileged application.

## Default Security Settings

### DM Access Control

By default, OpenJeeves requires explicit pairing for direct messages on most channels:

| Channel  | Default DM Policy |
| -------- | ----------------- |
| Discord  | `pairing`         |
| Slack    | `pairing`         |
| Telegram | `open`            |
| Signal   | `pairing`         |

### Pairing Flow

1. Unknown user sends a DM
2. OpenJeeves responds with a pairing code
3. Owner approves with: `openclaw pairing approve <channel> <code>`
4. User is added to allowlist

## Production Recommendations

### 1. Use Authentication

```json5
{
  gateway: {
    auth: {
      mode: "password",
      password: "secure-password",
    },
  },
}
```

### 2. Restrict Channel Access

```json5
{
  channels: {
    discord: {
      allowFrom: ["user-id-1", "user-id-2"],
    },
  },
}
```

### 3. Enable Sandbox for Non-Main Sessions

```json5
{
  agents: {
    defaults: {
      sandbox: {
        mode: "non-main",
        allow: ["bash", "read", "write"],
        deny: ["browser", "nodes"],
      },
    },
  },
}
```

### 4. Use Tailscale Instead of Public Exposure

```json5
{
  gateway: {
    tailscale: {
      mode: "serve", // Not "funnel"
    },
    bind: "loopback",
  },
}
```

## Environment Variables

Store sensitive data in environment variables:

```bash
# Don't put tokens in config files
export OPENAI_API_KEY=sk-...
export DISCORD_BOT_TOKEN=xoxb...
export TELEGRAM_BOT_TOKEN=...
```

## Tool Security

### Dangerous Tools

The following tools require special consideration:

- `exec` - Runs shell commands
- `browser` - Controls browser
- `write` - Writes files to disk
- `nodes` - Executes on paired devices

### Sandbox Modes

| Mode       | Description                           |
| ---------- | ------------------------------------- |
| `off`      | No sandbox (default for main session) |
| `non-main` | Sandbox for groups/channels only      |
| `all`      | Sandbox all sessions                  |

## Security Audit

Run the security audit:

```bash
openclaw doctor --security
```

## Reporting Security Issues

If you find a security vulnerability, please report it responsibly.

## Best Practices

1. **Keep it local**: Run on your local network, not publicly exposed
2. **Use pairing**: Keep `dmPolicy: "pairing"` for unknown users
3. **Limit tools**: Use sandbox mode for non-main sessions
4. **Review messages**: Check incoming messages before acting
5. **Update regularly**: Keep OpenJeeves updated
6. **Monitor logs**: Check gateway logs for suspicious activity
