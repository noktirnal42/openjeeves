// Stub exports for acpx package - the npm package doesn't export runtime subpath correctly
// This is a workaround to get the build working

export const ACPX_BACKEND_ID = "acpx";

export interface AcpRuntimeOptions {
  sessionStore?: unknown;
  // Add other options as needed
}

export interface AcpSessionRecord {
  name?: string;
  [key: string]: unknown;
}

export interface AcpLoadedSessionRecord {
  name?: string;
  [key: string]: unknown;
}

export interface AcpSessionStore {
  load(sessionId: string): Promise<AcpLoadedSessionRecord | undefined>;
  save(record: AcpSessionRecord): Promise<void>;
}

export interface AcpRuntimeHandle {
  sessionKey: string;
  [key: string]: unknown;
}

export interface AcpRuntimeTurnInput {
  sessionKey: string;
  message?: unknown;
  [key: string]: unknown;
}

export interface AcpRuntimeEvent {
  type: string;
  [key: string]: unknown;
}

export interface AcpRuntimeCapabilities {
  supportsStreaming?: boolean;
  [key: string]: unknown;
}

export interface AcpRuntimeStatus {
  active: boolean;
  [key: string]: unknown;
}

export interface AcpRuntimeDoctorReport {
  healthy: boolean;
  issues: string[];
}

export type AcpAgentRegistry = unknown;

export class AcpxRuntime {
  private _healthy = false;
  
  constructor(_options: AcpRuntimeOptions) {
    // Silently fail - this is a stub
  }
  
  isHealthy(): boolean {
    return this._healthy;
  }
  
  async probeAvailability(): Promise<void> {
    this._healthy = false;
    throw new Error("AcpxRuntime not available - acpx package import issue");
  }
  
  async doctor(): Promise<AcpRuntimeDoctorReport> {
    return {
      healthy: false,
      issues: ["AcpxRuntime stub - acpx package import issue"],
    };
  }
  
  async ensureSession(_input: { sessionKey: string }): Promise<AcpRuntimeHandle> {
    throw new Error("AcpxRuntime not available");
  }
  
  async *runTurn(_input: AcpRuntimeTurnInput): AsyncGenerator<AcpRuntimeEvent> {
    throw new Error("AcpxRuntime not available");
  }
  
  getCapabilities(): AcpRuntimeCapabilities {
    return {};
  }
  
  async getStatus(_input: { handle: AcpRuntimeHandle }): Promise<AcpRuntimeStatus> {
    return { active: false };
  }
  
  async setMode(_input: { mode: string }): Promise<void> {
    throw new Error("AcpxRuntime not available");
  }
  
  async setConfigOption(_input: { key: string; value: unknown }): Promise<void> {
    throw new Error("AcpxRuntime not available");
  }
  
  async cancel(_input: { handle: AcpRuntimeHandle }): Promise<void> {
    throw new Error("AcpxRuntime not available");
  }
  
  async prepareFreshSession(_input: { sessionKey: string }): Promise<void> {
    // No-op for stub
  }
  
  async close(_input: { handle: AcpRuntimeHandle; reason?: string }): Promise<void> {
    // No-op for stub
  }
}

export function createAcpRuntime(options: AcpRuntimeOptions): AcpxRuntime {
  return new AcpxRuntime(options);
}

export function createAgentRegistry(): AcpAgentRegistry {
  return {};
}

export function createFileSessionStore(_options: unknown): AcpSessionStore {
  return {
    async load(_sessionId: string): Promise<AcpLoadedSessionRecord | undefined> {
      return undefined;
    },
    async save(_record: AcpSessionRecord): Promise<void> {
      // No-op
    },
  };
}

export function decodeAcpxRuntimeHandleState(_encoded: string): unknown {
  throw new Error("AcpxRuntime not available");
}

export function encodeAcpxRuntimeHandleState(_state: unknown): string {
  throw new Error("AcpxRuntime not available");
}
