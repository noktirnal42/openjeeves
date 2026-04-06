/**
 * Unified Tool Registry
 * Combines Claude Code tools with OpenClaw tools, preferring Claude Code implementations
 * where they are superior or complementary.
 */
const fs = require("node:fs");
const path = require("node:path");

// Import Claude Code tools
const claudeTools = require('./tools/index.js');

// We'll lazily load OpenClaw tools to avoid circular dependencies
let _openclawToolsCache = null;

function getOpenClawTools() {
  if (_openclawToolsCache) {return _openclawToolsCache;}
  
  try {
    // In a real implementation, we would import from OpenClaw's tool system
    // For now, we'll return an empty array and note that OpenClaw tools
    // are available through the existing system
    _openclawToolsCache = [];
    return _openclawToolsCache;
  } catch (err) {
    console.warn('Could not load OpenClaw tools:', err);
    return [];
  }
}

function getAllTools() {
  const claudeToolList = [
    claudeTools.TodoWriteTool,
    claudeTools.TaskCreateTool,
    claudeTools.TaskListTool,
    claudeTools.TaskGetTool,
    claudeTools.TaskStopTool,
    claudeTools.TaskUpdateTool,
  ];
  
  const openclawToolList = getOpenClawTools();
  
  // Combine them, with Claude Code tools taking precedence when there are conflicts
  // In a full implementation, we'd do proper deduplication by tool name
  return [...claudeToolList, ...openclawToolList];
}

function getToolByName(name) {
  // First check Claude Code tools
  const claudeToolList = [
    claudeTools.TodoWriteTool,
    claudeTools.TaskCreateTool,
    claudeTools.TaskListTool,
    claudeTools.TaskGetTool,
    claudeTools.TaskStopTool,
    claudeTools.TaskUpdateTool,
  ];
  
  for (const tool of claudeToolList) {
    if (tool.name === name) {
      return tool;
    }
  }
  
  // Then check OpenClaw tools
  const openclawTools = getOpenClawTools();
  for (const tool of openclawTools) {
    if (tool.name === name) {
      return tool;
    }
  }
  
  return null;
}

module.exports = {
  getAllTools,
  getToolByName,
  // Export individual Claude Code tools for direct access
  TodoWriteTool: claudeTools.TodoWriteTool,
  TaskCreateTool: claudeTools.TaskCreateTool,
  TaskListTool: claudeTools.TaskListTool,
  TaskGetTool: claudeTools.TaskGetTool,
  TaskStopTool: claudeTools.TaskStopTool,
  TaskUpdateTool: claudeTools.TaskUpdateTool,
};