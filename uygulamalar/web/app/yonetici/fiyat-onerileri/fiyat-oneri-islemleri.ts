'use server';

import { revalidatePath } from 'next/cache';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';

export async function approvePriceSuggestion(suggestionId: string): Promise<{ error?: string }> {
  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return { error: 'Yetkisiz' };

  const { data, error } = await (supabase as any).rpc('admin_approve_menu_price_suggestion_v1', {
    p_suggestion_id: suggestionId,
  });
  if (error || !data?.ok) return { error: data?.error ?? error?.message ?? 'Onaylanamadı' };

  revalidatePath('/yonetici/fiyat-onerileri');
  return {};
}

export async function rejectPriceSuggestion(suggestionId: string, note?: string | null): Promise<{ error?: string }> {
  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return { error: 'Yetkisiz' };

  const { data, error } = await (supabase as any).rpc('admin_reject_menu_price_suggestion_v1', {
    p_suggestion_id: suggestionId,
    p_note: note ?? null,
  });
  if (error || !data?.ok) return { error: data?.error ?? error?.message ?? 'Reddedilemedi' };

  revalidatePath('/yonetici/fiyat-onerileri');
  return {};
}
