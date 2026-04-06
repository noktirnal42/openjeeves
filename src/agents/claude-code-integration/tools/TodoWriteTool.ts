import fs from "node:fs/promises";
import path from "node:path";
import type { AgentTool, AgentToolResult } from "@mariozechner/pi-agent-core";
import type { TSchema } from "@sinclair/typebox";
import { z } from "zod";
import { Static } from "@sinclair/typebox";

// Define the input schema using TypeBox for compatibility with OpenClaw's tool system
const TodoWriteSchema = {
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
} as const;

type TodoWriteInput = Static<typeof TodoWriteSchema>;

// Define the output schema
const TodoWriteResultSchema = {
  type: "object",
  properties: {
    oldTodos: { type: "array" },
    newTodos: { type: "array" },
  },
} as const;

type TodoWriteResult = Static<typeof TodoWriteResultSchema>;

/**
 * Todo Write Tool - Ported from Claude Code
 * Manages a structured task list for tracking progress on complex tasks.
 * Implements OpenClaw's AgentTool interface.
 */
export const TodoWriteTool: AgentToolWithMeta<typeof TodoWriteSchema, TodoWriteResult> = {
  name: "todo_write",
  label: "todo_write",
  displaySummary: "Manage session task checklist",
  
  get description() {
    return `Update the todo list for the current session. To be used proactively and often to track progress and pending tasks. Make sure that at least one task is in_progress at all times. Always provide both content (imperative) and activeForm (present continuous) for each task.`;
  },
  
  parameters: TodoWriteSchema,
  
  ownerOnly: false,
  
  async execute(_toolCallId: string, args: unknown, _signal: AbortSignal, _onUpdate: (output: AgentToolResult) => void): Promise<AgentToolResult> {
    const input = args as TodoWriteInput;
    
    // For simplicity, we'll use a global todo list keyed by agentId or session
    // In a full implementation, this would integrate with OpenClaw's state system
    const todoKey = "global"; // In practice, this would be derived from context
    
    // Read existing todos from a simple file-based storage for demo
    // In production, this would use OpenClaw's proper state management
    const memoryDir = path.join(process.env.HOME || '/tmp', '.openjeeves');
    const todosFile = path.join(memoryDir, 'todos.json');
    
    let oldTodos: any[] = [];
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
      toolUseId: _toolCallId,
      output: {
        oldTodos,
        newTodos,
      },
    };
  },
};