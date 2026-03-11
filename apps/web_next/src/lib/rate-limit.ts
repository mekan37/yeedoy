type RateLimitRecord = {
  count: number;
  resetAt: number;
};

const store = new Map<string, RateLimitRecord>();

export function rateLimit(key: string, limit: number, windowMs: number) {
  const timestamp = Date.now();
  const current = store.get(key);

  if (!current || current.resetAt <= timestamp) {
    const next = { count: 1, resetAt: timestamp + windowMs };
    store.set(key, next);
    return { ok: true, remaining: limit - 1, resetAt: next.resetAt };
  }

  if (current.count >= limit) {
    return { ok: false, remaining: 0, resetAt: current.resetAt };
  }

  current.count += 1;
  store.set(key, current);
  return { ok: true, remaining: limit - current.count, resetAt: current.resetAt };
}

export function getRequestIdentity(input: {
  ip?: string | null;
  userAgent?: string | null;
}) {
  return [input.ip?.trim() || 'unknown-ip', input.userAgent?.trim() || 'unknown-ua'].join(':');
}
