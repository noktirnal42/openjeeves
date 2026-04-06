# Channels

OpenJeeves supports multiple messaging channels. This guide covers setup for each supported platform.

## Supported Channels

| Channel         | Status       | Notes                   |
| --------------- | ------------ | ----------------------- |
| Discord         | ✅ Supported | Bot token required      |
| Telegram        | ✅ Supported | Bot token required      |
| Slack           | ✅ Supported | Bot + App tokens        |
| WhatsApp        | ✅ Supported | QR code pairing         |
| Signal          | ✅ Supported | signal-cli required     |
| iMessage        | ✅ Supported | BlueBubbles recommended |
| Microsoft Teams | ✅ Supported | Bot Framework           |
| Matrix          | ✅ Supported | Matrix SDK              |
| Google Chat     | ✅ Supported | Google Cloud            |

## Discord Setup

1. Create a new application at [Discord Developer Portal](https://discord.com/developers/applications)
2. Go to Bot > Reset Token and copy your token
3. Enable Message Content Intent in Bot > Privileged Gateway Intents
4. Invite the bot with `applications.commands` and `bot` scopes

```bash
openclaw channels login discord --token YOUR_TOKEN
```

## Telegram Setup

1. Create a bot via [@BotFather](https://t.me/botfather)
2. Copy the bot token

```bash
openclaw channels login telegram --token YOUR_TOKEN
```

## Slack Setup

1. Create a new Slack app at [Slack API](https://api.slack.com/apps)
2. Enable Bot Token Scope and subscribe to events
3. Install to workspace

```bash
openclaw channels login slack --bot-token xoxb-... --app-token xapp-...
```

## WhatsApp Setup

```bash
openclaw channels login whatsapp
```

This will display a QR code to scan with your phone.

## Signal Setup

Requires [signal-cli](https://github.com/AsamK/signal-cli) to be installed:

```bash
# Register or link your number
signal-cli -u YOUR_NUMBER link

# Configure in OpenJeeves
openclaw config set channels.signal.account YOUR_ACCOUNT
```

## Environment Variables

You can also configure channels via environment variables:

```bash
export DISCORD_BOT_TOKEN=your-token
export TELEGRAM_BOT_TOKEN=your-token
export SLACK_BOT_TOKEN=xoxb-...
export SLACK_APP_TOKEN=xapp-...
```

## Channel Allowlisting

Control who can message the assistant:

```json5
{
  channels: {
    discord: {
      allowFrom: ["user1", "user2"], // Specific users
      // or
      allowFrom: ["*"], // Allow everyone
    },
  },
}
```

## DM Policies

| Policy    | Description                        |
| --------- | ---------------------------------- |
| `pairing` | Unknown senders get a pairing code |
| `open`    | Anyone can message                 |
| `closed`  | No DMs allowed                     |

```json5
channels: {
  discord: {
    dmPolicy: "pairing",
  },
}
```
