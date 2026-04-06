# Getting Started with OpenJeeves

OpenJeeves is your personal AI assistant that combines the best of OpenClaw with Claude Code features. This guide will help you get up and running quickly.

## Prerequisites

- **Node.js**: Version 22+ (24 recommended)
- **Package Manager**: pnpm, npm, or bun
- **Operating System**: macOS, Linux, or Windows (WSL2 recommended)

## Quick Start

### 1. Clone the Repository

```bash
git clone https://github.com/noktirnal42/openjeeves.git
cd openjeeves
```

### 2. Install Dependencies

```bash
pnpm install
```

### 3. Build the UI (Required First Time)

```bash
pnpm ui:build
```

### 4. Build the Backend

```bash
pnpm build
```

### 5. Run the Gateway

```bash
pnpm openclaw gateway run --bind loopback --port 18789
```

### 6. Access the Control UI

Open your browser and navigate to:

```
http://localhost:18789
```

## Configuration

### Basic Configuration

Create a configuration file at `~/.openclaw/openclaw.json`:

```json5
{
  agent: {
    model: "openai/gpt-4.5",
  },
}
```

### Adding Channels

```json5
{
  agent: {
    model: "openai/gpt-4.5",
  },
  channels: {
    discord: {
      token: "your-discord-bot-token",
    },
    telegram: {
      botToken: "your-telegram-bot-token",
    },
  },
}
```

## Using the Agents

OpenJeeves comes with four specialized agents:

| Agent      | Command          | Description                 |
| ---------- | ---------------- | --------------------------- |
| **Jeeves** | Default          | General-purpose assistant   |
| **Jewel**  | `/agent verify`  | Verification and validation |
| **Apex**   | `/agent explore` | Codebase exploration        |
| **Cypher** | `/agent plan`    | Planning and organization   |

Switch agents using the agent selector in the chat interface.

## Tools

OpenJeeves includes Claude Code tools:

- `todo_write` - Create and manage todo lists
- `task_create` - Spawn background tasks
- `task_list` - List running tasks
- `task_stop` - Stop a running task
- `read` - Read files
- `write` - Write files
- `edit` - Edit files
- `glob` - Find files by pattern
- `grep` - Search file contents
- `exec` - Run shell commands

## Next Steps

- Read the [Configuration Guide](configuration.md) for advanced settings
- Check [Channels](channels.md) for messaging platform setup
- Explore [Skills](skills.md) for automation
- Review [Security](security.md) for production deployment
