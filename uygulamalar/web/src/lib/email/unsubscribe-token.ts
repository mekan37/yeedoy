/**
 * Stateless HMAC-SHA256 imzalı unsubscribe token yardımcısı.
 *
 * Token yapısı (noktayla ayrılmış 5 parça):
 *   {type}.{userIdB64}.{businessIdB64}.{expiresUnix}.{sig}
 *
 * type        : "mkt" | "biz"
 * userIdB64   : UUID → base64url (e-posta adresi hiçbir zaman taşınmaz)
 * businessIdB64: UUID → base64url ("mkt" türünde nil UUID kullanılır)
 * expiresUnix : Unix saniye cinsinden son geçerlilik zamanı
 * sig         : HMAC-SHA256(type.userIdB64.businessIdB64.expiresUnix, secret) → base64url
 *
 * Güvenlik notları:
 * - Token veritabanında saklanmaz (stateless). İdempotent: aynı token tekrar
 *   kullanılırsa sonuç değişmez (zaten false olan değer false kalır).
 * - Timing-safe karşılaştırma Node.js crypto.timingSafeEqual() ile yapılır.
 * - UNSUBSCRIBE_HMAC_SECRET yoksa üretim ve doğrulama redde düşer.
 * - Public unsubscribe route yalnızca izin KAPATMA yapabilir, açma yapamaz.
 */

import { createHmac, timingSafeEqual } from 'node:crypto';
import { logger } from '@/src/lib/kayitci';

// "mkt" türünde business_id alanını doldurmak için kullanılan nil UUID.
const NIL_UUID = '00000000-0000-0000-0000-000000000000';

// Varsayılan token geçerlilik süresi: 30 gün (saniye cinsinden)
const DEFAULT_TTL_SEC = 30 * 24 * 60 * 60;

export type UnsubscribeTokenType = 'mkt' | 'biz';

export type UnsubscribeTokenPayload = {
  type: UnsubscribeTokenType;
  userId: string;
  /** "mkt" türünde null döner. */
  businessId: string | null;
};

// ---------------------------------------------------------------------------
// Base64url helpers (Node built-in Buffer kullanır, tarayıcıda çalışmaz)
// ---------------------------------------------------------------------------

function toBase64url(input: string): string {
  return Buffer.from(input, 'utf8')
    .toString('base64')
    .replace(/\+/g, '-')
    .replace(/\//g, '_')
    .replace(/=+$/, '');
}

function fromBase64url(input: string): string {
  const padded = input.replace(/-/g, '+').replace(/_/g, '/');
  const padding = (4 - (padded.length % 4)) % 4;
  return Buffer.from(padded + '='.repeat(padding), 'base64').toString('utf8');
}

// ---------------------------------------------------------------------------
// HMAC helper
// ---------------------------------------------------------------------------

function computeHmac(payload: string, secret: string): string {
  return createHmac('sha256', secret)
    .update(payload)
    .digest('base64')
    .replace(/\+/g, '-')
    .replace(/\//g, '_')
    .replace(/=+$/, '');
}

function getSecret(): string | null {
  return process.env.UNSUBSCRIBE_HMAC_SECRET?.trim() || null;
}

// ---------------------------------------------------------------------------
// Public API
// ---------------------------------------------------------------------------

/**
 * Yeni bir unsubscribe token üretir.
 *
 * @param userId       Kullanıcı UUID'si (zorunlu)
 * @param businessId   İşletme UUID'si; "mkt" türünde null geçilebilir
 * @param type         "mkt" (global) veya "biz" (işletme bazlı)
 * @param ttlSec       Token geçerlilik süresi saniye cinsinden (varsayılan 30 gün)
 * @returns            URL'de güvenle kullanılabilecek token string
 * @throws             UNSUBSCRIBE_HMAC_SECRET tanımlı değilse Error fırlatır
 */
export function generateUnsubscribeToken(
  userId: string,
  businessId: string | null,
  type: UnsubscribeTokenType,
  ttlSec: number = DEFAULT_TTL_SEC,
): string {
  const secret = getSecret();
  if (!secret) {
    throw new Error('unsubscribe-token: UNSUBSCRIBE_HMAC_SECRET is not configured');
  }

  const effectiveBusinessId = type === 'mkt' ? NIL_UUID : (businessId ?? NIL_UUID);
  const expiresUnix = Math.floor(Date.now() / 1000) + ttlSec;

  const userIdB64 = toBase64url(userId);
  const businessIdB64 = toBase64url(effectiveBusinessId);
  const payload = `${type}.${userIdB64}.${businessIdB64}.${expiresUnix}`;
  const sig = computeHmac(payload, secret);

  return `${payload}.${sig}`;
}

/**
 * Token'ı doğrular ve payload'ını döner.
 *
 * Döndürdüğü değer:
 * - Geçerli token → UnsubscribeTokenPayload
 * - Geçersiz/süresi dolmuş/kötü biçimli → null
 *
 * Hiçbir zaman exception fırlatmaz; hataları loglar.
 */
export function verifyUnsubscribeToken(token: string): UnsubscribeTokenPayload | null {
  const secret = getSecret();
  if (!secret) {
    logger.warn('unsubscribe-token: UNSUBSCRIBE_HMAC_SECRET is not configured — rejecting all tokens');
    return null;
  }

  const parts = token.split('.');
  if (parts.length !== 5) {
    logger.warn('unsubscribe-token: malformed token (wrong part count)', { parts: parts.length });
    return null;
  }

  const [type, userIdB64, businessIdB64, expiresUnixStr, sig] = parts;

  // Tür kontrolü
  if (type !== 'mkt' && type !== 'biz') {
    logger.warn('unsubscribe-token: unknown type', { type });
    return null;
  }

  // Süre kontrolü
  const expiresUnix = parseInt(expiresUnixStr, 10);
  if (isNaN(expiresUnix)) {
    logger.warn('unsubscribe-token: invalid expiresUnix');
    return null;
  }

  const nowUnix = Math.floor(Date.now() / 1000);
  if (nowUnix > expiresUnix) {
    logger.warn('unsubscribe-token: token expired', { expiredAt: expiresUnix, now: nowUnix });
    return null;
  }

  // İmza doğrulama (timing-safe)
  const expectedPayload = `${type}.${userIdB64}.${businessIdB64}.${expiresUnixStr}`;
  const expectedSig = computeHmac(expectedPayload, secret);

  let sigMatches = false;
  try {
    sigMatches = timingSafeEqual(Buffer.from(sig, 'utf8'), Buffer.from(expectedSig, 'utf8'));
  } catch {
    // timingSafeEqual uzunluk uyuşmazlığında fırlatır
    sigMatches = false;
  }

  if (!sigMatches) {
    logger.warn('unsubscribe-token: signature mismatch');
    return null;
  }

  // Payload decode
  let userId: string;
  let rawBusinessId: string;

  try {
    userId = fromBase64url(userIdB64);
    rawBusinessId = fromBase64url(businessIdB64);
  } catch {
    logger.warn('unsubscribe-token: base64url decode failed');
    return null;
  }

  // UUID biçim kontrolü (kaba)
  const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
  if (!UUID_RE.test(userId)) {
    logger.warn('unsubscribe-token: invalid userId UUID format');
    return null;
  }

  const businessId = type === 'mkt' ? null : rawBusinessId;

  if (type === 'biz' && businessId && !UUID_RE.test(businessId)) {
    logger.warn('unsubscribe-token: invalid businessId UUID format');
    return null;
  }

  return { type: type as UnsubscribeTokenType, userId, businessId };
}
