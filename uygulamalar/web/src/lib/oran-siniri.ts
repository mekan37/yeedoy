import { createSupabasePublicClient } from '@/src/lib/taban/acik';
import { logger } from '@/src/lib/kayitci';

export type RateLimitResult = { ok: boolean; remaining: number; resetAt: number };

// Önceden süreç-içi bir Map kullanılıyordu — serverless'te (Vercel Fluid
// Compute) her instance kendi sayacını tutuyordu, gerçek limit
// "limit × aktif instance sayısı"na gevşiyordu. rate_limit_check_v1 RPC'si
// (bkz. migration 20260911000006) atomik UPSERT ile paylaşılan, race-
// condition-safe bir sayaç sağlıyor. RPC zaten anon'a açık (rate-limit
// kontrolü kimlik gerektirmez), service-role'e ihtiyaç yok.
//
// DB erişilemezse FAIL OPEN edilir (izin verilir, uyarı loglanır) —
// rate-limit'in amacı kötüye kullanımı sınırlamak; bir DB kesintisinde
// tüm meşru trafiği reddetmek daha kötü bir sonuç olurdu.
export async function rateLimit(key: string, limit: number, windowMs: number): Promise<RateLimitResult> {
  try {
    const supabase = createSupabasePublicClient();
    const { data, error } = await (supabase as unknown as {
      rpc: (fn: 'rate_limit_check_v1', args: { p_key: string; p_limit: number; p_window_ms: number }) =>
        Promise<{ data: Array<{ ok: boolean; remaining: number; reset_at: string }> | null; error: unknown }>;
    }).rpc('rate_limit_check_v1', { p_key: key, p_limit: limit, p_window_ms: windowMs });

    if (error || !data || data.length === 0) {
      logger.warn('rateLimit: RPC başarısız, fail-open', { key, error });
      return { ok: true, remaining: limit, resetAt: Date.now() + windowMs };
    }

    const row = data[0];
    return { ok: row.ok, remaining: row.remaining, resetAt: new Date(row.reset_at).getTime() };
  } catch (err) {
    logger.warn('rateLimit: beklenmeyen hata, fail-open', { key, err });
    return { ok: true, remaining: limit, resetAt: Date.now() + windowMs };
  }
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
 * yazdığı header'lardan çıkarır. Dağıtım Vercel — Cloudflare önünde değil,
 * bu yüzden `cf-connecting-ip`'e GÜVENİLMİYOR (istemci bu header'ı serbestçe
 * gönderip her IP-bazlı korumayı sahteleyebilirdi). Önce Vercel'in kendi
 * eklediği `x-real-ip`, o da yoksa `x-forwarded-for` zincirinin SON halkası
 * (zincirdeki tek client'ın kontrol edemeyeceği, doğrudan bağlanan proxy'nin
 * eklediği değer) kullanılır.
 */
export function getClientIp(headers: { get(name: string): string | null }): string | null {
  const realIp = headers.get('x-real-ip')?.trim();
  if (realIp) return realIp;

  const forwardedFor = headers.get('x-forwarded-for');
  if (forwardedFor) {
    const hops = forwardedFor.split(',').map((h) => h.trim()).filter(Boolean);
    if (hops.length > 0) return hops[hops.length - 1];
  }

  return null;
}
