/**
 * OpenJeeves Claude Code Integration
 * 
 * This module integrates Claude Code features into OpenJeeves:
 * - Ported tools (TodoWrite, Task management, etc.)
 * - Session Memory system
 * - Agent system
 * - Skills system
 * - Model-agnostic design (works with Ollama, LM Studio, OpenRouter)
 */

// Export all the integrated features
import { TodoWriteTool, TaskCreateTool, TaskListTool, TaskGetTool, TaskStopTool, TaskUpdateTool } from './tools/index.js';
import { SessionMemoryService } from './services/session-memory.js';
import { AgentRegistry } from './agents/agent-registry.js';
import { SkillsRegistry } from './skills/skills-registry.js';

export { TodoWriteTool, TaskCreateTool, TaskListTool, TaskGetTool, TaskStopTool, TaskUpdateTool };
export { SessionMemoryService };
export { AgentRegistry, SkillsRegistry };

// Version info
export const version = '1.0.0';
export const description = 'Claude Code features integrated into OpenJeeves - model agnostic';