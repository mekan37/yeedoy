'use server';

import { revalidatePath } from 'next/cache';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { hasPermission } from '@/src/lib/yetki-kontrol';

export async function approveSuggestion(suggestionId: string): Promise<{ error?: string }> {
  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return { error: 'Yetkisiz' };
  // RPC zaten is_admin() ile korunuyor — page:oneriler kontrolü
  // savunma-derinliği için ekleniyor.
  if (!(await hasPermission('page:oneriler'))) return { error: 'Yetkisiz' };

  const { data, error } = await (supabase).rpc('admin_approve_business_suggestion_v1', {
    p_suggestion_id: suggestionId,
  }) as { data: { ok: boolean; error?: string } | null; error: { message: string } | null };
  if (error || !data?.ok) return { error: data?.error ?? error?.message ?? 'Onaylanamadı' };

  revalidatePath('/yonetici/oneriler');
  return {};
}

export async function rejectSuggestion(suggestionId: string, note?: string | null): Promise<{ error?: string }> {
  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return { error: 'Yetkisiz' };
  if (!(await hasPermission('page:oneriler'))) return { error: 'Yetkisiz' };

  const { data, error } = await (supabase).rpc('admin_reject_business_suggestion_v1', {
    p_suggestion_id: suggestionId,
    p_admin_note: note ?? undefined,
  }) as { data: { ok: boolean; error?: string } | null; error: { message: string } | null };
  if (error || !data?.ok) return { error: data?.error ?? error?.message ?? 'Reddedilemedi' };

  revalidatePath('/yonetici/oneriler');
  return {};
}
