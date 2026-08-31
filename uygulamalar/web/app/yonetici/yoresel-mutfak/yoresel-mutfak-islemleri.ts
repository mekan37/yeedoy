'use server';

import { revalidatePath } from 'next/cache';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { checkAdminAccess } from '@/src/lib/auth/admin-guard';
import { logger } from '@/src/lib/kayitci';

type IslemSonucu = { ok: true } | { ok: false; error: string };
type KaydetSonucu = { ok: true; id: string } | { ok: false; error: string };

export async function etiketKaydet(id: string | null, city: string, label: string): Promise<KaydetSonucu> {
  const guard = await checkAdminAccess();
  if (!guard.authorized) return { ok: false, error: 'Bu işlem için yetkiniz yok.' };
  if (!city.trim() || !label.trim()) return { ok: false, error: 'Şehir ve etiket adı zorunlu.' };

  const supabase = await createSupabaseServerClient();
  const sb = supabase as unknown as { rpc: (fn: string, args: Record<string, unknown>) => Promise<{ data: unknown; error: unknown }> };

  const { data, error } = await sb.rpc('admin_upsert_regional_cuisine_tag_v1', {
    p_id: id,
    p_city: city.trim(),
    p_label: label.trim(),
  });

  if (error || typeof data !== 'string') {
    logger.warn('etiketKaydet: RPC hatası', { error, id });
    const rawMessage = (error as { message?: string } | null)?.message;
    const match = rawMessage?.match(/^(validation_error|not_found):\s*(.+)$/);
    return { ok: false, error: match ? match[2] : 'Etiket kaydedilemedi, tekrar deneyin.' };
  }

  revalidatePath('/yonetici/yoresel-mutfak');
  return { ok: true, id: data };
}

export async function etiketSil(id: string): Promise<IslemSonucu> {
  const guard = await checkAdminAccess();
  if (!guard.authorized) return { ok: false, error: 'Bu işlem için yetkiniz yok.' };

  const supabase = await createSupabaseServerClient();
  const sb = supabase as unknown as { rpc: (fn: string, args: Record<string, unknown>) => Promise<{ data: unknown; error: unknown }> };

  const { error } = await sb.rpc('admin_delete_regional_cuisine_tag_v1', { p_id: id });
  if (error) {
    logger.warn('etiketSil: RPC hatası', { error, id });
    return { ok: false, error: 'Etiket silinemedi, tekrar deneyin.' };
  }

  revalidatePath('/yonetici/yoresel-mutfak');
  return { ok: true };
}

export type IsletmeAramaSonucu = { id: string; name: string; city: string; current_tag_label: string | null };

export async function isletmeAra(query: string): Promise<IsletmeAramaSonucu[]> {
  const guard = await checkAdminAccess();
  if (!guard.authorized) return [];

  const supabase = await createSupabaseServerClient();
  const sb = supabase as unknown as { rpc: (fn: string, args: Record<string, unknown>) => Promise<{ data: unknown; error: unknown }> };

  const { data, error } = await sb.rpc('admin_search_businesses_for_tagging_v1', { p_query: query });
  if (error) {
    logger.warn('isletmeAra: RPC hatası', { error, query });
  }
  return Array.isArray(data) ? (data as IsletmeAramaSonucu[]) : [];
}

export async function isletmeyeEtiketAta(businessId: string, tagId: string | null): Promise<IslemSonucu> {
  const guard = await checkAdminAccess();
  if (!guard.authorized) return { ok: false, error: 'Bu işlem için yetkiniz yok.' };

  const supabase = await createSupabaseServerClient();
  const sb = supabase as unknown as { rpc: (fn: string, args: Record<string, unknown>) => Promise<{ data: unknown; error: unknown }> };

  const { error } = await sb.rpc('admin_set_business_regional_tag_v1', { p_business_id: businessId, p_tag_id: tagId });
  if (error) {
    logger.warn('isletmeyeEtiketAta: RPC hatası', { error, businessId });
    return { ok: false, error: 'Etiket atanamadı, tekrar deneyin.' };
  }

  revalidatePath('/yonetici/yoresel-mutfak');
  return { ok: true };
}
