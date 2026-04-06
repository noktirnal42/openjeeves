/**
 * Task List Tool - Ported from Claude Code
 * Lists all active background tasks.
 */
import fs from "node:fs/promises";
import path from "node:path";

class TaskListTool {
  constructor() {
    this.name = "task_list";
    this.label = "task_list";
    this.displaySummary = "List background tasks";
  }
  
  get description() {
    return `List all active background tasks. Use this to check the status of tasks you've created with task_create.`;
  }
  
  get parameters() {
    return {
      type: "object",
      properties: {},
    };
  }
  
  ownerOnly = false;
  
  async execute(toolCallId, args, signal, onUpdate) {
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
      // If file doesn't exist or is invalid, return empty list
      tasks = {};
    }
    
    return {
      type: "tool-result",
      toolUseId: toolCallId,
      output: {
        tasks: Object.values(tasks).map(task => ({
          id: task.id,
          title: task.title,
          description: task.description,
          status: task.status,
          createdAt: task.createdAt,
        })),
      },
    };
  }
}

export { TaskListTool };