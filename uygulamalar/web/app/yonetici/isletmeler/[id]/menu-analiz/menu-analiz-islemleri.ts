'use server';

import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { checkAdminAccess } from '@/src/lib/auth/admin-guard';
import { logger } from '@/src/lib/kayitci';
import { rateLimit } from '@/src/lib/oran-siniri';
import {
  menuExtractorStartSourceDiscoveryJob,
  menuExtractorPollJob,
} from '@/src/lib/menu-analiz/disari-cagri';
import {
  discoveryOutcomeMessage,
  normalizeExtractResult,
  parseDiscoveryOutcome,
  type DiscoveryOutcome,
} from './menu-analiz-yardimcilari';

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

  const started = await menuExtractorStartSourceDiscoveryJob(trimmedUrl);
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
  sourceType: string | null;
  discoveryOutcome: DiscoveryOutcome | null;
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
    | { status: string; error_message: string | null; external_job_id: string | null; source_type: string | null; source_url: string | null; result: unknown }
    | null
    | undefined;
  if (!job) return { ok: false, error: 'Analiz kaydı bulunamadı, sayfa yenilenmiş olabilir.' };

  // Zaten terminal durumdaysa dış servise tekrar sorulmaz — idempotent, gereksiz istek yok.
  if (job.status === 'finished' || job.status === 'failed') {
    return {
      ok: true,
      data: {
        status: job.status,
        errorMessage: job.error_message,
        sourceType: job.source_type,
        discoveryOutcome: parseDiscoveryOutcome(job.result),
      },
    };
  }

  if (!job.external_job_id) {
    return { ok: true, data: { status: (job.status as MenuAnalizDurum['status']) ?? 'queued', errorMessage: null, sourceType: job.source_type, discoveryOutcome: null } };
  }

  const poll = await menuExtractorPollJob(job.external_job_id);

  if (poll.status === 'finished') {
    const items = normalizeExtractResult(poll.result);
    if (process.env.NODE_ENV === 'development') {
      const discovery = poll.result && typeof poll.result === 'object' && !Array.isArray(poll.result)
        ? poll.result as Record<string, unknown>
        : null;
      logger.info('[menu-analysis]', {
        input_url: job.source_url,
        job_id: job.external_job_id,
        job_status: 'finished',
        discovery_status: discovery?.outcome_status ?? discovery?.status ?? null,
        selected_source: discovery?.selected_source ?? null,
        extraction_started: discovery?.extraction_started ?? null,
        extraction_finished: discovery?.extraction_finished ?? null,
        extracted_item_count: discovery?.extracted_item_count ?? null,
        normalized_item_count: items.length,
      });
    }
    const { error: finishError } = await sb.rpc('admin_finish_menu_extract_job_v1', {
      p_job_id: jobId,
      p_result: poll.result ?? {},
      p_items: items,
    });
    if (finishError) {
      logger.error('menuAnalizDurumSorgula: finish RPC hatası', { error: finishError, jobId });
      return { ok: false, error: 'Analiz sonucu kaydedilemedi, tekrar deneyin.' };
    }
    return {
      ok: true,
      data: {
        status: 'finished',
        errorMessage: null,
        sourceType: job.source_type,
        discoveryOutcome: parseDiscoveryOutcome(poll.result),
      },
    };
  }

  if (poll.status === 'failed') {
    const errorMessage = discoveryOutcomeMessage(poll.error) ?? poll.error;
    const { error: failError } = await sb.rpc('admin_fail_menu_extract_job_v1', {
      p_job_id: jobId,
      p_error_message: errorMessage,
    });
    if (failError) {
      logger.error('menuAnalizDurumSorgula: fail RPC hatası', { error: failError, jobId });
    }
    return { ok: true, data: { status: 'failed', errorMessage, sourceType: job.source_type, discoveryOutcome: null } };
  }

  if (poll.status === 'error') {
    if (poll.code === 'AUTH_ERROR') {
      const { error: failError } = await sb.rpc('admin_fail_menu_extract_job_v1', {
        p_job_id: jobId,
        p_error_message: poll.error,
      });
      if (failError) logger.error('menuAnalizDurumSorgula: auth fail RPC hatası', { error: failError, jobId });
      return { ok: true, data: { status: 'failed', errorMessage: poll.error, sourceType: job.source_type, discoveryOutcome: null } };
    }
    // Extractor'a ulaşılamadı — DB durumuna dokunulmaz, istemci bir sonraki
    // poll turunda tekrar dener.
    return { ok: false, error: poll.error };
  }

  return { ok: true, data: { status: poll.status, errorMessage: null, sourceType: job.source_type, discoveryOutcome: null } };
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
