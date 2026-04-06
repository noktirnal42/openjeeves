# Skills

OpenJeeves includes a skills system for extending functionality through modular packages.

## Built-in Skills

OpenJeeves comes with several built-in skills:

| Skill         | Description                          |
| ------------- | ------------------------------------ |
| `code-review` | Analyze and review code changes      |
| `debug`       | Help debug issues and errors         |
| `test`        | Generate and run tests               |
| `refactor`    | Suggest code improvements            |
| `document`    | Generate documentation               |
| `optimize`    | Performance optimization suggestions |

## Using Skills

### Via Chat Command

```
/skill code-review
```

### Via Tool

Use the skill system in your prompts:

```
Use the code-review skill to analyze this PR.
```

## Installing Additional Skills

### From ClawHub

```bash
openclaw skills install <skill-name>
```

### From npm

```bash
openclaw skills install @username/skill-name
```

### From Local Directory

```bash
openclaw skills install ./my-skill
```

## Creating Custom Skills

### Skill Structure

```
my-skill/
├── SKILL.md          # Required: Skill definition
├── index.ts          # Entry point
├── skills/
│   └── my-skill.ts   # Skill implementation
└── package.json
```

### SKILL.md Format

```markdown
# My Skill

Description of what the skill does.

## Usage

How to use the skill.

## Tools

- tool1: Description
- tool2: Description
```

### Example Skill

```typescript
// index.ts
import type { OpenClawSkill } from "openclaw/plugin-sdk";

export const mySkill: OpenClawSkill = {
  id: "my-skill",
  name: "My Skill",
  description: "Does something useful",

  async execute(context) {
    // Skill implementation
    return { result: "success" };
  },
};
```

## Skill Configuration

Configure skills in your `openclaw.json`:

```json5
{
  skills: {
    enabled: ["code-review", "debug"],
    config: {
      "code-review": {
        severity: "high",
      },
    },
  },
}
```

## Workspace Skills

Create skills in your workspace:

```bash
mkdir -p ~/.openclaw/workspace/skills/my-skill
```

## Disabling Skills

```bash
openclaw skills disable <skill-name>
```

## Updating Skills

```bash
openclaw skills update
```
