/**
 * Session Memory Service - Ported from Claude Code
 * Automatically maintains a markdown file with notes about the current conversation.
 * Runs periodically in the background without interrupting the main conversation.
 */
class SessionMemoryService {
  constructor() {
    this.enabled = true;
    this.autoExtract = true;
    this.extractionInterval = 10; // messages between extractions
    this.memoryFilePath = `${process.env.HOME || '/tmp'}/.openjeeves/memory.md`;
    this.maxMemorySize = 50000; // max chars in memory file
    this.messageCount = 0;
    
    // Initialize the memory file if it doesn't exist
    this._initialize();
  }
  
  _initialize() {
    const memoryDir = path.dirname(this.memoryFilePath);
    try {
      require("node:fs").mkdirSync(memoryDir, { recursive: true });
      if (!require("node:fs").existsSync(this.memoryFilePath)) {
        require("node:fs").writeFileSync(this.memoryFilePath, '# Session Memory\n\n');
      }
    } catch (err) {
      console.warn('Failed to initialize session memory:', err);
    }
  }
  
  configure(config) {
    if (config.enabled !== undefined) {this.enabled = config.enabled;}
    if (config.autoExtract !== undefined) {this.autoExtract = config.autoExtract;}
    if (config.extractionInterval !== undefined) {this.extractionInterval = config.extractionInterval;}
    if (config.memoryFilePath !== undefined) {this.memoryFilePath = config.memoryFilePath;}
    if (config.maxMemorySize !== undefined) {this.maxMemorySize = config.maxMemorySize;}
    
    // Re-initialize with new settings
    this._initialize();
  }
  
  recordMessage() {
    if (!this.enabled || !this.autoExtract) {return;}
    
    this.messageCount++;
    
    if (this.messageCount >= this.extractionInterval) {
      this.messageCount = 0;
      this._extractMemory();
    }
  }
  
  _extractMemory() {
    // This would call the LLM to analyze recent messages and extract key information
    // For now, this is a placeholder that adds a timestamp
    const timestamp = new Date().toISOString();
    const entry = `\n- [${timestamp}] Automatic memory extraction point\n`;
    this._appendToMemory(entry);
  }
  
  _appendToMemory(content) {
    try {
      let existing = '';
      if (require("node:fs").existsSync(this.memoryFilePath)) {
        existing = require("node:fs").readFileSync(this.memoryFilePath, 'utf8');
      }
      
      // Truncate if too large
      if (existing.length + content.length > this.maxMemorySize) {
        existing = existing.slice(-this.maxMemorySize / 2);
        existing = '# Session Memory (truncated)\n\n' + existing;
      }
      
      require("node:fs").writeFileSync(this.memoryFilePath, existing + '\n' + content);
    } catch (err) {
      console.warn('Failed to write to session memory:', err);
    }
  }
  
  readMemory() {
    try {
      if (!require("node:fs").existsSync(this.memoryFilePath)) {return '';}
      return require("node:fs").readFileSync(this.memoryFilePath, 'utf-8');
    } catch (err) {
      console.warn('Failed to read session memory:', err);
      return '';
    }
  }
  
  writeMemory(content) {
    try {
      let existing = '';
      if (require("node:fs").existsSync(this.memoryFilePath)) {
        existing = require("node:fs").readFileSync(this.memoryFilePath, 'utf-8');
      }
      
      // Truncate if too large
      if (existing.length + content.length > this.maxMemorySize) {
        existing = existing.slice(-this.maxMemorySize / 2);
        existing = '# Session Memory (truncated)\n\n' + existing;
      }
      
      require("node:fs").writeFileSync(this.memoryFilePath, existing + '\n' + content);
    } catch (err) {
      console.warn('Failed to write to session memory:', err);
    }
  }
  
  clearMemory() {
    try {
      require("node:fs").writeFileSync(this.memoryFilePath, '# Session Memory\n\n');
    } catch (err) {
      console.warn('Failed to clear session memory:', err);
    }
  }
}

export { SessionMemoryService };