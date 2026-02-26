const buckets = new Map<string, { count: number; resetAt: number }>();

export function hitRateLimit(key: string, limit = 12, windowMs = 60_000) {
  const now = Date.now();
  const row = buckets.get(key);
  if (!row || row.resetAt < now) {
    buckets.set(key, { count: 1, resetAt: now + windowMs });
    return false;
  }
  row.count += 1;
  if (row.count > limit) return true;
  return false;
}
