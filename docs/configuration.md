# Configuration Reference

Complete configuration reference for OpenJeeves.

## Top-Level Configuration

```json5
{
  // Agent configuration
  agent: {
    // Model to use (provider/model format)
    model: "openai/gpt-4.5",

    // Reasoning level: "off", "minimal", "low", "medium", "high", "xhigh"
    reasoningLevel: "medium",

    // Custom system prompt
    systemPrompt: "You are Jeeves, a helpful AI assistant.",
  },

  // Channel configurations
  channels: {
    discord: {
      /* ... */
    },
    telegram: {
      /* ... */
    },
    slack: {
      /* ... */
    },
    whatsapp: {
      /* ... */
    },
  },

  // Gateway settings
  gateway: {
    // Bind address
    bind: "loopback",
    // Port number
    port: 18789,
    // Authentication
    auth: {
      mode: "password",
      password: "your-password",
    },
  },

  // TTS settings
  messages: {
    tts: {
      enabled: true,
      provider: "elevenlabs",
    },
  },
}
```

## Agent Configuration

| Key              | Type   | Description                                                          |
| ---------------- | ------ | -------------------------------------------------------------------- |
| `model`          | string | Model to use (format: `provider/model`)                              |
| `reasoningLevel` | string | Reasoning effort: `off`, `minimal`, `low`, `medium`, `high`, `xhigh` |
| `systemPrompt`   | string | Custom system prompt                                                 |
| `workspace`      | string | Path to workspace directory                                          |

## Channel Configuration

### Discord

```json5
channels: {
  discord: {
    token: "your-bot-token",
    allowFrom: ["*"],  // Allow from all users
    guilds: {},         // Guild-specific config
  },
}
```

### Telegram

```json5
channels: {
  telegram: {
    botToken: "your-bot-token",
    allowFrom: ["*"],
  },
}
```

### Slack

```json5
channels: {
  slack: {
    botToken: "xoxb-...",
    appToken: "xapp-...",
  },
}
```

## Gateway Configuration

| Key                   | Type    | Default      | Description                              |
| --------------------- | ------- | ------------ | ---------------------------------------- |
| `bind`                | string  | `"loopback"` | Bind address                             |
| `port`                | number  | `18789`      | Port number                              |
| `auth.mode`           | string  | `"none"`     | Auth mode: `none`, `password`, `token`   |
| `auth.password`       | string  | -            | Auth password                            |
| `auth.allowTailscale` | boolean | `true`       | Allow Tailscale connections              |
| `tailscale.mode`      | string  | `"off"`      | Tailscale mode: `off`, `serve`, `funnel` |

## Security

See [Security](security.md) for production security settings.
