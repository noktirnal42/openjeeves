/**
 * Task Create Tool - Ported from Claude Code
 * Creates a new background task/agent to work on a specific goal.
 */
import fs from "node:fs/promises";
import path from "node:path";

class TaskCreateTool {
  constructor() {
    this.name = "task_create";
    this.label = "task_create";
    this.displaySummary = "Create background task";
  }
  
  get description() {
    return `Create a new background task/agent to work on a specific goal. The task will run asynchronously and you can check its status and output later.`;
  }
  
  get parameters() {
    return {
      type: "object",
      properties: {
        title: { type: "string" },
        description: { type: "string" },
        prompt: { type: "string" },
      },
      required: ["title", "prompt"],
    };
  }
  
  ownerOnly = false;
  
  async execute(toolCallId, args, signal, onUpdate) {
    const { title, description = "", prompt } = args;
    
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
      // If file doesn't exist or is invalid, start with empty object
      tasks = {};
    }
    
    // Generate a simple task ID
    const taskId = `task_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
    
    // Create the task entry
    const newTask = {
      id: taskId,
      title,
      description,
      prompt,
      status: 'pending',
      createdAt: Date.now(),
      output: null,
      error: null,
    };
    
    // Add to tasks
    tasks[taskId] = newTask;
    
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
        taskId,
        status: 'pending',
      },
    };
  }
}

export { TaskCreateTool };