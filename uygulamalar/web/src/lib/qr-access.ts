// Re-export shim — canonical implementation is karekod-erisimi.ts
// See LOW-005 in docs/api-security-performance-audit.md
// Both files were logically identical; karekod-erisimi.ts kept as primary per Turkish-first convention.
export { canManageBusiness, getQrAccessState } from './karekod-erisimi';
