/**
 * Task Get Tool - Ported from Claude Code
 * Gets the output from a specific background task.
 */
import fs from "node:fs/promises";
import path from "node:path";

class TaskGetTool {
  constructor() {
    this.name = "task_get";
    this.label = "task_get";
    this.displaySummary = "Get task output";
  }
  
  get description() {
    return `Get the output from a specific background task by its ID. Use this to check the results of a task you created with task_create.`;
  }
  
  get parameters() {
    return {
      type: "object",
      properties: {
        taskId: { type: "string" },
      },
      required: ["taskId"],
    };
  }
  
  ownerOnly = false;
  
  async execute(toolCallId, args, signal, onUpdate) {
    const { taskId } = args;
    
    // Simple file-based storage for tasks
    const memoryDir = path.join(process.env.HOME || '/tmp', '.openjeeves');
    const tasksFile = path.join(memoryDir, 'tasks.json');
    
    let tasks = {};
    try {
      await fs.mkdir(memoryDir, { recursive: true });
      if (await fs.access(tasksFile).then(() => true).catch(() => false)) {
        const data = await fs.readFile(tasksFile, 'utf8');
        tasks = JSON.parse(data);
      }
    } catch (err) {
      // If file doesn't exist or is invalid, task not found
      return {
        type: "tool-result",
        toolUseId: toolCallId,
        output: {
          error: `Task not found: ${taskId}`,
        },
        isError: true,
      };
    }
    
    const task = tasks[taskId];
    if (!task) {
      return {
        type: "tool-result",
        toolUseId: toolCallId,
        output: {
          error: `Task not found: ${taskId}`,
        },
        isError: true,
      };
    }
    
    return {
      type: "tool-result",
      toolUseId: toolCallId,
      output: {
        id: task.id,
        title: task.title,
        description: task.description,
        status: task.status,
        createdAt: task.createdAt,
        output: task.output,
        error: task.error,
      },
    };
  }
}

export { TaskGetTool };