'use server';

import { revalidatePath } from 'next/cache';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { checkAdminAccess } from '@/src/lib/auth/admin-guard';
import { logger } from '@/src/lib/kayitci';

type IslemSonucu = { ok: true } | { ok: false; error: string };

type SbRpc = { rpc: (fn: string, args?: Record<string, unknown>) => Promise<{ data: unknown; error: unknown }> };

export interface ZincirAramaSonucu {
  id: string;
  name: string;
  category: string | null;
}

export async function zincirAra(query: string): Promise<ZincirAramaSonucu[]> {
  const guard = await checkAdminAccess();
  if (!guard.authorized) return [];

  const trimmed = query.trim();
  if (!trimmed) return [];

  const supabase = await createSupabaseServerClient();
  const { data, error } = await supabase
    .from('chains')
    .select('id, name, category')
    .ilike('name', `%${trimmed}%`)
    .order('name', { ascending: true })
    .limit(10);

  if (error) {
    logger.warn('zincirAra: sorgu hatası', { error, query: trimmed });
    return [];
  }

  return (data ?? []).map((c) => ({ id: c.id, name: c.name, category: c.category ?? null }));
}

function zincirHatasiCevir(mesaj: string | undefined): string {
  if (!mesaj) return 'İşlem başarısız oldu, tekrar deneyin.';
  if (mesaj.includes('unauthorized')) return 'Bu işlem için yetkiniz yok.';
  if (mesaj.includes('not_found')) return 'Zincir bulunamadı.';
  if (mesaj.includes('validation_error: en az bir işletme')) return 'En az bir işletme seçmelisiniz.';
  if (mesaj.includes('validation_error: şu işletmeler zaten başka bir zincirde:')) {
    return mesaj.split('validation_error: ')[1] ?? mesaj;
  }
  return 'İşlem başarısız oldu, tekrar deneyin.';
}

export async function isletmeleriZincireBagla(chainId: string, businessIds: string[]): Promise<IslemSonucu> {
  const guard = await checkAdminAccess();
  if (!guard.authorized) return { ok: false, error: 'Bu işlem için yetkiniz yok.' };
  if (!chainId) return { ok: false, error: 'Zincir seçilmedi.' };
  if (businessIds.length === 0) return { ok: false, error: 'En az bir işletme seçmelisiniz.' };

  const supabase = await createSupabaseServerClient();
  const sb = supabase as unknown as SbRpc;

  const { error } = await sb.rpc('admin_add_businesses_to_chain_v1', {
    p_chain_id: chainId,
    p_business_ids: businessIds,
  });

  if (error) {
    logger.warn('isletmeleriZincireBagla: RPC hatası', { error, chainId, businessIds });
    const mesaj = (error as { message?: string } | null)?.message;
    return { ok: false, error: zincirHatasiCevir(mesaj) };
  }

  revalidatePath('/yonetici/isletmeler');
  revalidatePath('/yonetici/zincirler');
  return { ok: true };
}

export async function yeniZincirKurVeBagla(name: string, businessIds: string[]): Promise<IslemSonucu> {
  const guard = await checkAdminAccess();
  if (!guard.authorized) return { ok: false, error: 'Bu işlem için yetkiniz yok.' };
  if (!name.trim()) return { ok: false, error: 'Zincir adı zorunlu.' };
  if (businessIds.length === 0) return { ok: false, error: 'En az bir işletme seçmelisiniz.' };

  const supabase = await createSupabaseServerClient();
  const sb = supabase as unknown as SbRpc;

  const { data: createData, error: createError } = await sb.rpc('admin_create_chain_v1', {
    p_name: name.trim(),
  });

  if (createError) {
    logger.warn('yeniZincirKurVeBagla: admin_create_chain_v1 hatası', { error: createError, name });
    return { ok: false, error: 'Zincir oluşturulamadı, tekrar deneyin.' };
  }

  const created = createData as { ok?: boolean; chain_id?: string } | null;
  if (!created?.ok || !created.chain_id) {
    return { ok: false, error: 'Zincir oluşturulamadı, tekrar deneyin.' };
  }

  return isletmeleriZincireBagla(created.chain_id, businessIds);
}
