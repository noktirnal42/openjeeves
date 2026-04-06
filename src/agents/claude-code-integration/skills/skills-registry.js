/**
 * Skills Registry - Ported from Claude Code
 * Skills are specialized prompt templates for specific tasks.
 */
class SkillsRegistry {
  constructor() {
    this.skills = this._getBuiltinSkills();
  }
  
  _getBuiltinSkills() {
    return [
      {
        id: 'code-review',
        name: 'Code Review',
        description: 'Perform a thorough code review',
        prompt: 'Review the following code for correctness, performance, security, and best practices. Identify issues and suggest improvements.',
        category: 'coding',
        tags: ['review', 'quality', 'security', 'best-practices'],
      },
      {
        id: 'debug',
        name: 'Debug',
        description: 'Systematically debug an issue',
        prompt: 'Debug the following issue systematically. Identify root cause, reproduce the problem, and suggest fixes.',
        category: 'debugging',
        tags: ['debug', 'troubleshoot', 'root-cause'],
      },
      {
        id: 'test',
        name: 'Write Tests',
        description: 'Write comprehensive tests',
        prompt: 'Write comprehensive tests for the following code. Include unit tests, integration tests, and edge cases.',
        category: 'testing',
        tags: ['test', 'coverage', 'testing'],
      },
      {
        id: 'refactor',
        name: 'Refactor',
        description: 'Refactor code for clarity and performance',
        prompt: 'Refactor the following code to improve clarity, performance, and maintainability while preserving functionality.',
        category: 'coding',
        tags: ['refactor', 'cleanup', 'optimization'],
      },
      {
        id: 'document',
        name: 'Document',
        description: 'Generate documentation',
        prompt: 'Generate clear, comprehensive documentation for the following code. Include usage examples and API references.',
        category: 'documentation',
        tags: ['docs', 'comments', 'documentation'],
      },
      {
        id: 'optimize',
        name: 'Optimize Performance',
        description: 'Optimize code for better performance',
        prompt: 'Optimize the following code for better performance. Identify bottlenecks and suggest improvements.',
        category: 'coding',
        tags: ['performance', 'optimization', 'speed'],
      },
    ];
  }
  
  getSkill(id) {
    return this.skills.find(skill => skill.id === id) || null;
  }
  
  getAllSkills() {
    return [...this.skills];
  }
  
  searchSkills(query) {
    if (!query) return this.getAllSkills();
    const q = query.toLowerCase();
    return this.skills.filter(skill => 
      skill.name.toLowerCase().includes(q) ||
      skill.description.toLowerCase().includes(q) ||
      skill.tags.some(tag => tag.toLowerCase().includes(q))
    );
  }
  
  getSkillsByCategory(category) {
    if (!category) return this.getAllSkills();
    return this.skills.filter(skill => skill.category === category);
  }
}

export { SkillsRegistry };