'use server';

import { revalidatePath } from 'next/cache';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';

export async function approveSuggestion(suggestionId: string): Promise<{ error?: string }> {
  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return { error: 'Yetkisiz' };

  const { data, error } = await (supabase as any).rpc('admin_approve_business_suggestion_v1', {
    p_suggestion_id: suggestionId,
  });
  if (error || !data?.ok) return { error: data?.error ?? error?.message ?? 'Onaylanamadı' };

  revalidatePath('/yonetici/oneriler');
  return {};
}

export async function rejectSuggestion(suggestionId: string, note?: string | null): Promise<{ error?: string }> {
  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return { error: 'Yetkisiz' };

  const { data, error } = await (supabase as any).rpc('admin_reject_business_suggestion_v1', {
    p_suggestion_id: suggestionId,
    p_admin_note: note ?? null,
  });
  if (error || !data?.ok) return { error: data?.error ?? error?.message ?? 'Reddedilemedi' };

  revalidatePath('/yonetici/oneriler');
  return {};
}
