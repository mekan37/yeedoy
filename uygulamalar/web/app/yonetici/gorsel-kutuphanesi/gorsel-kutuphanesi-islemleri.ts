'use server';

import { revalidatePath } from 'next/cache';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { checkAdminAccess } from '@/src/lib/auth/admin-guard';
import { logger } from '@/src/lib/kayitci';

type IslemSonucu = { ok: true } | { ok: false; error: string };

export async function gorselKaydet(
  id: string | null,
  imageUrl: string,
  keywords: string[],
  isActive: boolean,
): Promise<IslemSonucu> {
  const guard = await checkAdminAccess();
  if (!guard.authorized) {
    return { ok: false, error: 'unauthorized' };
  }
  const trimmedKeywords = keywords.map((k) => k.trim()).filter(Boolean);
  if (!id && !imageUrl.trim()) {
    return { ok: false, error: 'image_url_required' };
  }

  const supabase = await createSupabaseServerClient();
  const sb = supabase as unknown as { rpc: (fn: string, args: Record<string, unknown>) => Promise<{ data: unknown; error: unknown }> };

  const { error } = await sb.rpc('admin_upsert_stock_dish_image_v1', {
    p_id: id,
    p_image_url: imageUrl.trim() || null,
    p_keywords: trimmedKeywords,
    p_is_active: isActive,
  });

  if (error) {
    logger.warn('gorselKaydet: RPC hatası', { error, id });
    return { ok: false, error: 'save_failed' };
  }

  revalidatePath('/yonetici/gorsel-kutuphanesi');
  return { ok: true };
}

export async function gorselPasiflestir(id: string, isActive: boolean): Promise<IslemSonucu> {
  const guard = await checkAdminAccess();
  if (!guard.authorized) {
    return { ok: false, error: 'unauthorized' };
  }

  const supabase = await createSupabaseServerClient();
  const sb = supabase as unknown as { rpc: (fn: string, args: Record<string, unknown>) => Promise<{ data: unknown; error: unknown }> };

  const { error } = await sb.rpc('admin_upsert_stock_dish_image_v1', {
    p_id: id,
    p_is_active: isActive,
  });

  if (error) {
    logger.warn('gorselPasiflestir: RPC hatası', { error, id });
    return { ok: false, error: 'update_failed' };
  }

  revalidatePath('/yonetici/gorsel-kutuphanesi');
  return { ok: true };
}

export async function gorselSil(id: string): Promise<IslemSonucu> {
  const guard = await checkAdminAccess();
  if (!guard.authorized) {
    return { ok: false, error: 'unauthorized' };
  }

  const supabase = await createSupabaseServerClient();
  const sb = supabase as unknown as { rpc: (fn: string, args: Record<string, unknown>) => Promise<{ data: unknown; error: unknown }> };

  const { error } = await sb.rpc('admin_delete_stock_dish_image_v1', { p_id: id });

  if (error) {
    logger.warn('gorselSil: RPC hatası', { error, id });
    return { ok: false, error: 'delete_failed' };
  }

  revalidatePath('/yonetici/gorsel-kutuphanesi');
  return { ok: true };
}
