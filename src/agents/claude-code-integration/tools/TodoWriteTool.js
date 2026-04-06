/**
 * Todo Write Tool - Ported from Claude Code
 * Manages a structured task list for tracking progress on complex tasks.
 */
import fs from "node:fs/promises";
import path from "node:path";

class TodoWriteTool {
  constructor() {
    this.name = "todo_write";
    this.label = "todo_write";
    this.displaySummary = "Manage session task checklist";
  }
  
  get description() {
    return `Update the todo list for the current session. To be used proactively and often to track progress and pending tasks. Make sure that at least one task is in_progress at all times. Always provide both content (imperative) and activeForm (present continuous) for each task.`;
  }
  
  get parameters() {
    return {
      type: "object",
      properties: {
        todos: {
          type: "array",
          items: {
            type: "object",
            properties: {
              content: { type: "string" },
              status: { type: "string", enum: ["pending", "in_progress", "completed"] },
              activeForm: { type: "string" },
            },
            required: ["content", "status"],
          },
        },
      },
      required: ["todos"],
    };
  }
  
  ownerOnly = false;
  
  async execute(toolCallId, args, signal, onUpdate) {
    const input = args;
    
    // Simple file-based storage for todos
    const todoKey = "global"; // In practice, this would be per-agent/session
    const memoryDir = path.join(process.env.HOME || '/tmp', '.openjeeves');
    const todosFile = path.join(memoryDir, 'todos.json');
    
    let oldTodos = [];
    try {
      await fs.mkdir(memoryDir, { recursive: true });
      if (await fs.access(todosFile).then(() => true).catch(() => false)) {
        const data = await fs.readFile(todosFile, 'utf8');
        oldTodos = JSON.parse(data);
      }
    } catch (err) {
      // If file doesn't exist or is invalid, start with empty array
      oldTodos = [];
    }
    
    // Update the todos
    const newTodos = input.todos;
    
    // Write back to file
    try {
      await fs.writeFile(todosFile, JSON.stringify(newTodos, null, 2));
    } catch (err) {
      // If we can't write, still return success but log the error
      console.warn('Failed to write todos:', err);
    }
    
    return {
      type: "tool-result",
      toolUseId: toolCallId,
      output: {
        oldTodos,
        newTodos,
      },
    };
  }
}

export { TodoWriteTool };