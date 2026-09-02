'use server';

import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { checkAdminAccess } from '@/src/lib/auth/admin-guard';
import { logger } from '@/src/lib/kayitci';
import { rateLimit } from '@/src/lib/oran-siniri';
import {
  menuExtractorStartUrlJob,
  menuExtractorPollJob,
} from '@/src/lib/menu-analiz/disari-cagri';

type SbRpc = { rpc: (fn: string, args?: Record<string, unknown>) => Promise<{ data: unknown; error: unknown }> };

type IslemSonucu = { ok: true } | { ok: false; error: string };

function rpcHatasiCevir(mesaj: string | undefined, fallback: string): string {
  if (!mesaj) return fallback;
  if (mesaj.includes('not_found')) return 'Kayıt bulunamadı, sayfa yenilenmiş olabilir.';
  if (mesaj.includes('unauthorized')) return 'Bu işlem için yetkiniz yok.';
  if (mesaj.includes('validation_error')) return 'Geçersiz değer girildi.';
  return fallback;
}

// ─── Job başlatma (URL) ──────────────────────────────────────────────────────
// Dosya yükleme aynı iş için app/sunucu/yonetici/menu-analiz/baslat/route.ts
// kullanır — Server Action'ların varsayılan body-size limiti 30MB dosya için
// yetersiz, route.ts bu kısıtı taşımıyor.

export async function menuAnalizBaslatUrl(businessId: string, url: string): Promise<{ ok: true; jobId: string } | { ok: false; error: string }> {
  const guard = await checkAdminAccess();
  if (!guard.authorized) return { ok: false, error: 'Bu işlem için yetkiniz yok.' };

  const trimmedUrl = url.trim();
  if (!trimmedUrl) return { ok: false, error: 'Menü URL\'si zorunlu.' };
  try {
    new URL(trimmedUrl);
  } catch {
    return { ok: false, error: 'Geçerli bir URL girin.' };
  }

  const limit = rateLimit(`menu-analiz-baslat:${guard.userId}`, 10, 60_000);
  if (!limit.ok) return { ok: false, error: 'Çok fazla istek. Lütfen biraz bekleyip tekrar deneyin.' };

  const started = await menuExtractorStartUrlJob(trimmedUrl);
  if (!started.ok) return { ok: false, error: started.error };

  const supabase = await createSupabaseServerClient();
  const sb = supabase as unknown as SbRpc;

  const { data, error } = await sb.rpc('admin_create_menu_extract_job_v1', {
    p_business_id: businessId,
    p_source_type: 'url',
    p_external_job_id: started.jobId,
    p_source_url: trimmedUrl,
    p_source_file_name: null,
  });

  if (error || !data) {
    logger.error('menuAnalizBaslatUrl: job kayıt RPC hatası', { error, businessId });
    return { ok: false, error: rpcHatasiCevir((error as { message?: string } | null)?.message, 'Analiz kaydı oluşturulamadı.') };
  }

  return { ok: true, jobId: data as string };
}

// ─── Durum sorgulama (poll) ──────────────────────────────────────────────────
// İlk kez 'finished' gözlemlendiğinde: normalizer çalışır + admin_finish_menu_extract_job_v1
// çağrılır (idempotent — tekrar poll edilirse items ikinci kez eklenmez).
// İlk kez 'failed' gözlemlendiğinde: admin_fail_menu_extract_job_v1 çağrılır.

export interface MenuAnalizDurum {
  status: 'queued' | 'started' | 'finished' | 'failed';
  errorMessage: string | null;
}

export async function menuAnalizDurumSorgula(jobId: string): Promise<{ ok: true; data: MenuAnalizDurum } | { ok: false; error: string }> {
  const guard = await checkAdminAccess();
  if (!guard.authorized) return { ok: false, error: 'Bu işlem için yetkiniz yok.' };

  const supabase = await createSupabaseServerClient();
  const sb = supabase as unknown as SbRpc;

  const { data: jobRows, error: jobError } = await sb.rpc('admin_get_menu_extract_job_v1', { p_job_id: jobId });
  if (jobError) {
    logger.warn('menuAnalizDurumSorgula: job RPC hatası', { error: jobError, jobId });
    return { ok: false, error: 'Analiz durumu alınamadı.' };
  }
  const job = (Array.isArray(jobRows) ? jobRows[0] : jobRows) as
    | { status: string; error_message: string | null; external_job_id: string | null }
    | null
    | undefined;
  if (!job) return { ok: false, error: 'Analiz kaydı bulunamadı, sayfa yenilenmiş olabilir.' };

  // Zaten terminal durumdaysa dış servise tekrar sorulmaz — idempotent, gereksiz istek yok.
  if (job.status === 'finished' || job.status === 'failed') {
    return { ok: true, data: { status: job.status, errorMessage: job.error_message } };
  }

  if (!job.external_job_id) {
    return { ok: true, data: { status: (job.status as MenuAnalizDurum['status']) ?? 'queued', errorMessage: null } };
  }

  const poll = await menuExtractorPollJob(job.external_job_id);

  if (poll.status === 'finished') {
    const items = normalizeExtractResult(poll.result);
    const { error: finishError } = await sb.rpc('admin_finish_menu_extract_job_v1', {
      p_job_id: jobId,
      p_result: poll.result ?? {},
      p_items: items,
    });
    if (finishError) {
      logger.error('menuAnalizDurumSorgula: finish RPC hatası', { error: finishError, jobId });
      return { ok: false, error: 'Analiz sonucu kaydedilemedi, tekrar deneyin.' };
    }
    return { ok: true, data: { status: 'finished', errorMessage: null } };
  }

  if (poll.status === 'failed') {
    const { error: failError } = await sb.rpc('admin_fail_menu_extract_job_v1', {
      p_job_id: jobId,
      p_error_message: poll.error,
    });
    if (failError) {
      logger.error('menuAnalizDurumSorgula: fail RPC hatası', { error: failError, jobId });
    }
    return { ok: true, data: { status: 'failed', errorMessage: poll.error } };
  }

  if (poll.status === 'error') {
    // Extractor'a ulaşılamadı — DB durumuna dokunulmaz, istemci bir sonraki
    // poll turunda tekrar dener.
    return { ok: false, error: poll.error };
  }

  return { ok: true, data: { status: poll.status, errorMessage: null } };
}

// ─── Normalizer ───────────────────────────────────────────────────────────────
// Extractor'ın `result` alanının kesin şekli garanti değil. Kalemleri olası
// birkaç anahtar altında arar, her alanı savunmacı biçimde ayıklar. Fiyatı
// bulunamayan/parse edilemeyen kalemler için price_cents HER ZAMAN null kalır
// — asla 0'a veya başka bir değere düşürülmez (bu özelliğin en kritik kuralı).

interface NormalizedExtractItem {
  category_name: string | null;
  name: string;
  description: string | null;
  price_cents: number | null;
  currency: string;
  confidence: number | null;
  requires_review: boolean;
  review_reasons: string[];
  warnings: string[];
}

const ITEM_ARRAY_KEYS = ['items', 'menu_items', 'menuItems', 'menu', 'products', 'dishes', 'entries'];

function locateItemsArray(result: unknown): unknown[] {
  if (Array.isArray(result)) return result;
  if (!result || typeof result !== 'object') return [];
  const r = result as Record<string, unknown>;
  for (const key of ITEM_ARRAY_KEYS) {
    if (Array.isArray(r[key])) return r[key] as unknown[];
  }
  // Bir seviye iç içe olabilir (ör. result.data.items)
  for (const value of Object.values(r)) {
    if (value && typeof value === 'object' && !Array.isArray(value)) {
      const nested = value as Record<string, unknown>;
      for (const key of ITEM_ARRAY_KEYS) {
        if (Array.isArray(nested[key])) return nested[key] as unknown[];
      }
    }
  }
  return [];
}

function coerceName(r: Record<string, unknown>): string | null {
  const candidates = [r.name, r.title, r.product_name, r.item_name, r.ad];
  for (const c of candidates) {
    if (typeof c === 'string' && c.trim()) return c.trim();
  }
  return null;
}

function coerceString(value: unknown): string | null {
  if (typeof value === 'string' && value.trim()) return value.trim();
  return null;
}

function coerceBoolean(value: unknown): boolean | null {
  return typeof value === 'boolean' ? value : null;
}

function coerceStringArray(value: unknown): string[] {
  if (!Array.isArray(value)) return [];
  return value
    .map((v) => (typeof v === 'string' ? v.trim() : typeof v === 'number' ? String(v) : null))
    .filter((v): v is string => !!v);
}

function coerceConfidence(value: unknown): number | null {
  const n = typeof value === 'number' ? value : typeof value === 'string' ? Number.parseFloat(value) : NaN;
  if (!Number.isFinite(n)) return null;
  if (n >= 0 && n <= 1) return n;
  if (n > 1 && n <= 100) return Math.round(n) / 100; // bazı extractor'lar 0-100 döndürebilir
  return null;
}

function parsePriceToCents(value: unknown): number | null {
  if (typeof value === 'number' && Number.isFinite(value) && value >= 0) {
    return Math.round(value * 100);
  }
  if (typeof value === 'string') {
    const cleaned = value.replace(/[^\d.,]/g, '').trim();
    if (!cleaned) return null;
    const lastComma = cleaned.lastIndexOf(',');
    const lastDot = cleaned.lastIndexOf('.');
    let normalized: string;
    if (lastComma > lastDot) {
      normalized = cleaned.replace(/\./g, '').replace(',', '.'); // "1.234,56" → "1234.56"
    } else if (lastDot > lastComma) {
      normalized = cleaned.replace(/,/g, ''); // "1,234.56" → "1234.56"
    } else {
      normalized = cleaned.replace(/,/g, '');
    }
    const n = Number.parseFloat(normalized);
    if (!Number.isFinite(n) || n < 0) return null;
    return Math.round(n * 100);
  }
  return null;
}

function coercePriceCents(r: Record<string, unknown>): number | null {
  if (typeof r.price_cents === 'number' && Number.isFinite(r.price_cents) && r.price_cents >= 0) {
    return Math.round(r.price_cents);
  }
  const candidates = [r.price, r.fiyat, r.amount, r.unit_price];
  for (const c of candidates) {
    const cents = parsePriceToCents(c);
    if (cents !== null) return cents;
  }
  return null;
}

function normalizeExtractResult(result: unknown): NormalizedExtractItem[] {
  const rawItems = locateItemsArray(result);
  const items: NormalizedExtractItem[] = [];

  for (const raw of rawItems) {
    if (!raw || typeof raw !== 'object') continue;
    const r = raw as Record<string, unknown>;

    const name = coerceName(r);
    if (!name) continue; // ad yoksa kalem kullanılamaz — atla

    const priceCents = coercePriceCents(r);
    const reviewReasons = coerceStringArray(r.review_reasons ?? r.reviewReasons ?? r.reasons);
    let requiresReview = coerceBoolean(r.requires_review ?? r.requiresReview) ?? false;

    if (priceCents === null) {
      requiresReview = true;
      if (!reviewReasons.includes('Fiyat bulunamadı')) reviewReasons.push('Fiyat bulunamadı');
    }

    items.push({
      category_name: coerceString(r.category_name ?? r.category ?? r.section ?? r.section_name ?? r.group),
      name,
      description: coerceString(r.description ?? r.desc),
      price_cents: priceCents,
      currency: coerceString(r.currency) ?? 'TRY',
      confidence: coerceConfidence(r.confidence),
      requires_review: requiresReview,
      review_reasons: reviewReasons,
      warnings: coerceStringArray(r.warnings),
    });
  }

  return items;
}

// ─── Taslak kalemler ─────────────────────────────────────────────────────────

export interface MenuAnalizOge {
  id: string;
  category_name: string | null;
  name: string;
  description: string | null;
  price_cents: number | null;
  currency: string;
  confidence: number | null;
  requires_review: boolean;
  review_reasons: string[];
  warnings: string[];
  excluded: boolean;
  imported: boolean;
  imported_menu_item_id: string | null;
}

export async function menuAnalizOgeleriListele(jobId: string): Promise<MenuAnalizOge[]> {
  const guard = await checkAdminAccess();
  if (!guard.authorized) return [];

  const supabase = await createSupabaseServerClient();
  const sb = supabase as unknown as SbRpc;
  const { data, error } = await sb.rpc('admin_list_menu_extract_items_v1', { p_job_id: jobId });
  if (error) {
    logger.warn('menuAnalizOgeleriListele: RPC hatası', { error, jobId });
    return [];
  }
  return (data as MenuAnalizOge[] | null) ?? [];
}

export async function menuAnalizOgeGuncelle(input: {
  itemId: string;
  categoryName: string | null;
  name: string;
  description: string | null;
  priceCents: number | null;
  currency: string;
}): Promise<IslemSonucu> {
  const guard = await checkAdminAccess();
  if (!guard.authorized) return { ok: false, error: 'Bu işlem için yetkiniz yok.' };
  if (!input.name.trim()) return { ok: false, error: 'Ürün adı zorunlu.' };
  if (input.priceCents !== null && input.priceCents < 0) return { ok: false, error: 'Fiyat negatif olamaz.' };

  const supabase = await createSupabaseServerClient();
  const sb = supabase as unknown as SbRpc;
  const { error } = await sb.rpc('admin_update_menu_extract_item_v1', {
    p_item_id: input.itemId,
    p_category_name: input.categoryName?.trim() || null,
    p_name: input.name.trim(),
    p_description: input.description?.trim() || null,
    p_price_cents: input.priceCents,
    p_currency: input.currency?.trim() || 'TRY',
  });

  if (error) {
    logger.warn('menuAnalizOgeGuncelle: RPC hatası', { error, itemId: input.itemId });
    return { ok: false, error: rpcHatasiCevir((error as { message?: string } | null)?.message, 'Öğe güncellenemedi, tekrar deneyin.') };
  }
  return { ok: true };
}

export async function menuAnalizOgeHaricTut(itemId: string, excluded: boolean): Promise<IslemSonucu> {
  const guard = await checkAdminAccess();
  if (!guard.authorized) return { ok: false, error: 'Bu işlem için yetkiniz yok.' };

  const supabase = await createSupabaseServerClient();
  const sb = supabase as unknown as SbRpc;
  const { error } = await sb.rpc('admin_set_menu_extract_item_excluded_v1', {
    p_item_id: itemId,
    p_excluded: excluded,
  });

  if (error) {
    logger.warn('menuAnalizOgeHaricTut: RPC hatası', { error, itemId });
    return { ok: false, error: rpcHatasiCevir((error as { message?: string } | null)?.message, 'Öğe güncellenemedi, tekrar deneyin.') };
  }
  return { ok: true };
}

// ─── Mevcut menü (diff için) ─────────────────────────────────────────────────

export interface IsletmeMenuOgesi {
  id: string;
  name: string;
  description: string | null;
  price_cents: number | null;
  currency: string;
  category_name: string | null;
}

export async function isletmeMenuOgeleriListele(businessId: string): Promise<IsletmeMenuOgesi[]> {
  const guard = await checkAdminAccess();
  if (!guard.authorized) return [];

  const supabase = await createSupabaseServerClient();
  const sb = supabase as unknown as SbRpc;
  const { data, error } = await sb.rpc('admin_list_business_menu_items_v1', { p_business_id: businessId });
  if (error) {
    logger.warn('isletmeMenuOgeleriListele: RPC hatası', { error, businessId });
    return [];
  }
  return (data as IsletmeMenuOgesi[] | null) ?? [];
}

// ─── Menüye aktarım ──────────────────────────────────────────────────────────

export interface MenuAnalizUygulaKarari {
  item_id: string;
  action: 'create' | 'update' | 'skip';
  target_menu_item_id?: string;
}

export type MenuAnalizUygulaSonucu =
  | { ok: true; created: number; updated: number; skipped: number }
  | { ok: false; error: string };

export async function menuAnalizUygula(jobId: string, decisions: MenuAnalizUygulaKarari[]): Promise<MenuAnalizUygulaSonucu> {
  const guard = await checkAdminAccess();
  if (!guard.authorized) return { ok: false, error: 'Bu işlem için yetkiniz yok.' };
  if (decisions.length === 0) return { ok: false, error: 'Aktarılacak öğe seçilmedi.' };

  const supabase = await createSupabaseServerClient();
  const sb = supabase as unknown as SbRpc;
  const { data, error } = await sb.rpc('admin_apply_menu_extract_job_v1', {
    p_job_id: jobId,
    p_decisions: decisions,
  });

  if (error) {
    logger.error('menuAnalizUygula: RPC hatası', { error, jobId });
    return { ok: false, error: rpcHatasiCevir((error as { message?: string } | null)?.message, 'Menüye aktarım başarısız oldu, tekrar deneyin.') };
  }

  const sonuc = data as { ok?: boolean; created?: number; updated?: number; skipped?: number } | null;
  if (!sonuc?.ok) return { ok: false, error: 'Menüye aktarım başarısız oldu, tekrar deneyin.' };

  return { ok: true, created: sonuc.created ?? 0, updated: sonuc.updated ?? 0, skipped: sonuc.skipped ?? 0 };
}
