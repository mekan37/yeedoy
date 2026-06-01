// Re-export shim — canonical implementation is oran-siniri.ts
// See MED-001 in docs/api-security-performance-audit.md
export { rateLimit, getRequestIdentity } from './oran-siniri';
