type RateLimitRecord = {
  count: number;
  resetAt: number;
};

const store = new Map<string, RateLimitRecord>();

const MAX_STORE_SIZE = 1_000;

function evictExpired(now: number) {
  // Only scan if store is getting large to avoid O(n) on every call
  if (store.size < MAX_STORE_SIZE) return;
  for (const [k, v] of store) {
    if (v.resetAt <= now) store.delete(k);
  }
}

export function rateLimit(key: string, limit: number, windowMs: number) {
  const timestamp = Date.now();
  evictExpired(timestamp);
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

/**
 * İstemcinin gerçek IP'sini, istemcinin doğrudan sahteleyebileceği
 * ham `x-forwarded-for` yerine güvenilir kenar/proxy katmanlarının
 * yazdığı header'lardan çıkarır: Cloudflare varsa `cf-connecting-ip`,
 * yoksa Vercel'in kendi eklediği `x-real-ip`, o da yoksa
 * `x-forwarded-for` zincirinin SON halkası (zincirdeki tek client'ın
 * kontrol edemeyeceği, doğrudan bağlanan proxy'nin eklediği değer).
 */
export function getClientIp(headers: Headers): string | null {
  const cfConnectingIp = headers.get('cf-connecting-ip')?.trim();
  if (cfConnectingIp) return cfConnectingIp;

  const realIp = headers.get('x-real-ip')?.trim();
  if (realIp) return realIp;

  const forwardedFor = headers.get('x-forwarded-for');
  if (forwardedFor) {
    const hops = forwardedFor.split(',').map((h) => h.trim()).filter(Boolean);
    if (hops.length > 0) return hops[hops.length - 1];
  }

  return null;
}
