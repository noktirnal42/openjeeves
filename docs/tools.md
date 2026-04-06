# Tools

OpenJeeves provides a rich set of tools for interacting with your system and files.

## File Operations

### read

Read the contents of a file.

```
Usage: read <file-path>
```

Example:

```
read /path/to/file.txt
```

### write

Write content to a file.

```
Usage: write <file-path> <content>
```

Example:

```
write /path/to/file.txt "Hello, World!"
```

### edit

Edit a specific part of a file.

```
Usage: edit <file-path> <old-string> <new-string>
```

## Search Operations

### glob

Find files matching a pattern.

```
Usage: glob <pattern>
```

Example:

```
glob **/*.ts
```

### grep

Search for text within files.

```
Usage: grep <pattern> <path>
```

Example:

```
grep "TODO" src/
```

## Shell Operations

### exec

Execute shell commands.

```
Usage: exec <command>
```

Example:

```
exec npm install
```

## Task Management

### task_create

Create a background task.

```
Usage: task_create <title> [--description <desc>] [--prompt <prompt>]
```

### task_list

List all background tasks.

```
Usage: task_list
```

### task_stop

Stop a running task.

```
Usage: task_stop <task-id>
```

### task_get

Get details of a specific task.

```
Usage: task_get <task-id>
```

## Todo Management

### todo_write

Create and manage todo lists.

```
Usage: todo_write <operation> <data>

Operations:
  - create <content>
  - update <id> <content>
  - delete <id>
  - list
```

## Session Tools

### sessions_list

List all active sessions.

```
Usage: sessions_list
```

### sessions_history

Get chat history for a session.

```
Usage: sessions_history <session-key>
```

### sessions_send

Send a message to another session.

```
Usage: sessions_send <session-key> <message>
```

## Browser Control

### browser

Control a browser instance (if enabled).

```
Usage: browser <action> <url>

Actions:
  - navigate
  - screenshot
  - click
  - type
```

## Node Operations

For macOS/iOS/Android nodes:

### system.run

Run a command on a connected device.

```
Usage: system.run <command>
```

### system.notify

Send a notification.

```
Usage: system.notify <message>
```

### camera.snap

Take a photo.

```
Usage: camera.snap
```

### location.get

Get device location.

```
Usage: location.get
```
