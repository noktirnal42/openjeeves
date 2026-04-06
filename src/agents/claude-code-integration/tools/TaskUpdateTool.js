/**
 * Task Update Tool - Ported from Claude Code
 * Updates an existing background task.
 */
import fs from "node:fs/promises";
import path from "node:path";

class TaskUpdateTool {
  constructor() {
    this.name = "task_update";
    this.label = "task_update";
    this.displaySummary = "Update background task";
  }
  
  get description() {
    return `Update an existing background task by its ID. Use this to modify the task's title, description, or prompt.`;
  }
  
  get parameters() {
    return {
      type: "object",
      properties: {
        taskId: { type: "string" },
        title: { type: "string" },
        description: { type: "string" },
        prompt: { type: "string" },
      },
      required: ["taskId"],
    };
  }
  
  ownerOnly = false;
  
  async execute(toolCallId, args, signal, onUpdate) {
    const { taskId, title, description, prompt } = args;
    
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
    
    if (!tasks[taskId]) {
      return {
        type: "tool-result",
        toolUseId: toolCallId,
        output: {
          error: `Task not found: ${taskId}`,
        },
        isError: true,
      };
    }
    
    // Update the task fields if provided
    if (title !== undefined) {tasks[taskId].title = title;}
    if (description !== undefined) {tasks[taskId].description = description;}
    if (prompt !== undefined) {tasks[taskId].prompt = prompt;}
    tasks[taskId].updatedAt = Date.now();
    
    // Write back to file
    try {
      await fs.writeFile(tasksFile, JSON.stringify(tasks, null, 2));
    } catch (err) {
      console.warn('Failed to write tasks:', err);
    }
    
    return {
      type: "tool-result",
      toolUseId: toolCallId,
      output: {
        id: taskId,
        title: tasks[taskId].title,
        description: tasks[taskId].description,
        status: tasks[taskId].status,
        updatedAt: tasks[taskId].updatedAt,
      },
    };
  }
}

export { TaskUpdateTool };