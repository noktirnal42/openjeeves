/**
 * Agent Registry - Ported from Claude Code
 * Defines built-in agents that can be spawned as sub-agents.
 */
class AgentRegistry {
  constructor() {
    this.agents = this._getBuiltinAgents();
  }
  
  _getBuiltinAgents() {
    return [
      {
        id: 'general-purpose',
        name: 'General Purpose Agent',
        description: 'A versatile agent for general coding tasks',
        systemPrompt: 'You are a helpful coding assistant. Help the user with coding tasks, debugging, and answering questions.',
        tools: ['read', 'write', 'edit', 'exec', 'glob', 'grep', 'todo_write', 'task_create'],
        canSpawnSubAgents: true,
        subAgentIds: ['verification', 'explore'],
        avatar: '/assets/avatars/jeeves.png',
      },
      {
        id: 'verification',
        name: 'Verification Agent',
        description: 'Specialized in verifying code changes and test results',
        systemPrompt: 'You are a verification specialist. Your job is to verify that code changes are correct, tests pass, and requirements are met.',
        tools: ['read', 'exec', 'glob', 'grep', 'todo_write'],
        canSpawnSubAgents: false,
        subAgentIds: [],
        avatar: '/assets/avatars/jewel.png',
      },
      {
        id: 'explore',
        name: 'Explore Agent',
        description: 'Specialized in exploring and understanding codebases',
        systemPrompt: 'You are a codebase exploration specialist. Help the user understand large codebases, find relevant files, and navigate complex systems.',
        tools: ['read', 'glob', 'grep', 'todo_write'],
        canSpawnSubAgents: false,
        subAgentIds: [],
        avatar: '/assets/avatars/apex.png',
      },
      {
        id: 'plan',
        name: 'Plan Agent',
        description: 'Creates detailed implementation plans',
        systemPrompt: 'You are a planning specialist. Create detailed, actionable plans for implementing features or solving problems.',
        tools: ['read', 'glob', 'grep', 'todo_write'],
        canSpawnSubAgents: false,
        subAgentIds: [],
        avatar: '/assets/avatars/cypher.png',
      },
    ];
  }
  
  getAgent(id) {
    return this.agents.find(agent => agent.id === id) || null;
  }
  
  getAllAgents() {
    return [...this.agents];
  }
  
  getAgentIds() {
    return this.agents.map(agent => agent.id);
  }
}

export { AgentRegistry };