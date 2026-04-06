/**
 * Task Stop Tool - Ported from Claude Code
 * Stops a running background task.
 */
import fs from "node:fs/promises";
import path from "node:path";

class TaskStopTool {
  constructor() {
    this.name = "task_stop";
    this.label = "task_stop";
    this.displaySummary = "Stop background task";
  }
  
  get description() {
    return `Stop a running background task by its ID. Use this to halt a task you created with task_create that is taking too long or is no longer needed.`;
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
    
    // Mark task as stopped
    tasks[taskId].status = 'stopped';
    tasks[taskId].stoppedAt = Date.now();
    
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
        status: 'stopped',
        stoppedAt: tasks[taskId].stoppedAt,
      },
    };
  }
}

export { TaskStopTool };