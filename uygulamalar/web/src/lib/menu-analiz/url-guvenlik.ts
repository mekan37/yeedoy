import { promises as dns } from 'node:dns';
import { isIP } from 'node:net';

// menu-analiz/baslat (URL akışı) ve kaynak-kesfi endpoint'leri, admin'in
// girdiği (aslında işletme sahibinin website_url'i olabilen, dolayısıyla
// güvenmediğimiz) bir URL'i dış menu-extractor servisine ilettiriyordu —
// hiçbir host allowlist/blocklist yoktu. website_url=http://169.254.169.254/
// veya http://localhost:6379 gibi bir değer, extractor servisinin (kendi ağı
// içinde) iç kaynaklara istek atmasına (SSRF) yol açabilirdi.
const BLOCKED_HOSTNAMES = new Set(['localhost', '0.0.0.0']);

function isPrivateOrReservedIp(ip: string): boolean {
  const version = isIP(ip);
  if (version === 4) {
    const parts = ip.split('.').map(Number);
    const [a, b] = parts;
    if (a === 10) return true; // 10.0.0.0/8
    if (a === 127) return true; // loopback
    if (a === 169 && b === 254) return true; // link-local / cloud metadata
    if (a === 172 && b >= 16 && b <= 31) return true; // 172.16.0.0/12
    if (a === 192 && b === 168) return true; // 192.168.0.0/16
    if (a === 0) return true; // 0.0.0.0/8
    return false;
  }
  if (version === 6) {
    const lower = ip.toLowerCase();
    if (lower === '::1') return true; // loopback
    if (lower.startsWith('fe80:') || lower.startsWith('fc') || lower.startsWith('fd')) return true; // link-local / unique-local
    if (lower.startsWith('::ffff:')) return isPrivateOrReservedIp(lower.slice('::ffff:'.length));
    return false;
  }
  return false;
}

export type UrlSafetyResult = { ok: true } | { ok: false; error: string };

/**
 * Dış bir servise iletilecek kullanıcı/işletme kaynaklı bir URL'in iç
 * ağa/localhost'a/bulut metadata endpoint'ine işaret etmediğini doğrular.
 * DNS çözümlemesi de yapar (hostname'in kendisi zararsız görünüp DNS'in
 * private bir IP'ye çözülmesi ihtimaline karşı — DNS rebinding).
 */
export async function assertSsrfSafeUrl(rawUrl: string): Promise<UrlSafetyResult> {
  let url: URL;
  try {
    url = new URL(rawUrl);
  } catch {
    return { ok: false, error: 'invalid_url' };
  }

  if (url.protocol !== 'http:' && url.protocol !== 'https:') {
    return { ok: false, error: 'unsupported_protocol' };
  }

  const hostname = url.hostname.toLowerCase();
  if (BLOCKED_HOSTNAMES.has(hostname) || hostname.endsWith('.local') || hostname.endsWith('.internal')) {
    return { ok: false, error: 'blocked_host' };
  }

  if (isIP(hostname)) {
    if (isPrivateOrReservedIp(hostname)) return { ok: false, error: 'blocked_host' };
    return { ok: true };
  }

  try {
    const records = await dns.lookup(hostname, { all: true });
    if (records.some((r) => isPrivateOrReservedIp(r.address))) {
      return { ok: false, error: 'blocked_host' };
    }
  } catch {
    // DNS çözümlenemiyorsa zaten extractor servisi de erişemeyecektir —
    // burada bloklamıyoruz, gerçek hata extractor'dan dönecek.
  }

  return { ok: true };
}
