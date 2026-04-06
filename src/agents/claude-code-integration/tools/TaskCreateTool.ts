import { z } from 'zod';
import { buildTool, type ToolDef } from '../../../tools/tool.js';

/**
 * Task Create Tool - Ported from Claude Code
 * Creates a new background task/agent to work on a specific goal.
 */
export const TaskCreateTool = buildTool({
  name: 'task_create',
  searchHint: 'create a new background task',
  maxResultSizeChars: 100_000,
  strict: true,

  async description() {
    return `Create a new background task/agent to work on a specific goal. The task will run asynchronously and you can check its status and output later.`;
  },

  async prompt() {
    return `Use this tool to create a new background task that will work on a specific objective. The task runs independently and you can check its progress and results later using task_list, task_get, and task_stop.

When to use this tool:
- When you want to delegate a sub-task to work on in parallel
- For long-running operations that shouldn't block your main workflow
- When you need to explore multiple approaches simultaneously
- For tasks that benefit from focused, dedicated attention

The task will be assigned a unique ID that you can use to reference it in subsequent tool calls.`;

  },
  get inputSchema(): z.Schema<any> {
    return z.object({
      title: z.string().describe("Short title of the task"),
      description: z.string().describe("Detailed description of what the task should accomplish"),
      prompt: z.string().describe("The specific prompt or instructions for the task to execute"),
    }).required(['title', 'prompt']);
  },
  get outputSchema(): z.Schema<any> {
    return z.object({
      taskId: z.string().describe("Unique identifier for the created task"),
      status: z.string().describe("Initial status of the task"),
    });
  },
  userFacingName() {
    return '';
  },
  shouldDefer: true,
  isEnabled() {
    return true;
  },
  async checkPermissions(input) {
    return { behavior: 'allow', updatedInput: input };
  },
  renderToolUseMessage() {
    return null;
  },
  async call({ title, description, prompt }, context) {
    const state = context.getAppState();
    const tasks = state.tasks || {};
    
    // Generate a simple task ID (in practice this would be more robust)
    const taskId = `task_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
    
    // Create the task entry
    const newTask = {
      id: taskId,
      title,
      description: description || "",
      prompt,
      status: 'pending',
      createdAt: Date.now(),
      output: null,
      error: null,
    };

    // Add to state
    context.setAppState(prev => ({
      ...prev,
      tasks: {
        ...prev.tasks,
        [taskId]: newTask,
      },
    }));

    return {
      data: {
        taskId,
        status: 'pending',
      },
    };
  },
});