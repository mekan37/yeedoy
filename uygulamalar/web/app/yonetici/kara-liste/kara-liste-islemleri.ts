'use server';

import { revalidatePath } from 'next/cache';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { checkAdminAccess } from '@/src/lib/auth/admin-guard';
import { logger } from '@/src/lib/kayitci';

type IslemSonucu = { ok: true } | { ok: false; error: string };

export type BlacklistTerim = { id: number; term: string; is_active: boolean; created_at: string };

export async function terimAra(query: string): Promise<BlacklistTerim[]> {
  const guard = await checkAdminAccess();
  if (!guard.authorized) return [];

  const supabase = await createSupabaseServerClient();
  const sb = supabase as unknown as { rpc: (fn: string, args: Record<string, unknown>) => Promise<{ data: unknown; error: unknown }> };

  const { data, error } = await sb.rpc('admin_list_blacklist_terms_v1', { p_query: query, p_limit: 50, p_offset: 0 });
  if (error) {
    logger.warn('terimAra: RPC hatası', { error, query });
  }
  return Array.isArray(data) ? (data as BlacklistTerim[]) : [];
}

export async function terimEkle(term: string): Promise<IslemSonucu> {
  const guard = await checkAdminAccess();
  if (!guard.authorized) return { ok: false, error: 'Bu işlem için yetkiniz yok.' };
  if (!term.trim()) return { ok: false, error: 'Terim boş olamaz.' };

  const supabase = await createSupabaseServerClient();
  const sb = supabase as unknown as { rpc: (fn: string, args: Record<string, unknown>) => Promise<{ data: unknown; error: unknown }> };

  const { error } = await sb.rpc('admin_add_blacklist_term_v1', { p_term: term.trim() });
  if (error) {
    logger.warn('terimEkle: RPC hatası', { error, term });
    return { ok: false, error: 'Terim eklenemedi, tekrar deneyin.' };
  }

  revalidatePath('/yonetici/kara-liste');
  return { ok: true };
}

export async function terimSil(id: number): Promise<IslemSonucu> {
  const guard = await checkAdminAccess();
  if (!guard.authorized) return { ok: false, error: 'Bu işlem için yetkiniz yok.' };

  const supabase = await createSupabaseServerClient();
  const sb = supabase as unknown as { rpc: (fn: string, args: Record<string, unknown>) => Promise<{ data: unknown; error: unknown }> };

  const { error } = await sb.rpc('admin_remove_blacklist_term_v1', { p_id: id });
  if (error) {
    logger.warn('terimSil: RPC hatası', { error, id });
    return { ok: false, error: 'Terim silinemedi, tekrar deneyin.' };
  }

  revalidatePath('/yonetici/kara-liste');
  return { ok: true };
}
