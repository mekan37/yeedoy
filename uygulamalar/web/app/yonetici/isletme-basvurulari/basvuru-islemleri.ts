'use server';

import { revalidatePath } from 'next/cache';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';

async function assertAdmin() {
  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return { error: 'Kimlik dogrulanamadi', supabase: null };

  const { data: profile } = await (supabase as any)
    .rpc('is_admin');

  if (!profile) {
    return { error: 'Kimlik dogrulanamadi', supabase: null };
  }

  return { error: null, supabase };
}

export async function approveSubmission(id: string): Promise<{ error?: string }> {
  const { error, supabase } = await assertAdmin();
  if (error || !supabase) return { error: error ?? 'Kimlik dogrulanamadi' };

  await (supabase as any)
    .from('business_submissions')
    .update({ status: 'approved' })
    .eq('id', id);

  revalidatePath('/yonetici/isletme-basvurulari');
  return {};
}

export async function rejectSubmission(
  id: string,
  reason?: string,
): Promise<{ error?: string }> {
  const { error, supabase } = await assertAdmin();
  if (error || !supabase) return { error: error ?? 'Kimlik dogrulanamadi' };

  const update: Record<string, string> = { status: 'rejected' };
  if (reason?.trim()) update.admin_note = reason.trim();

  await (supabase as any)
    .from('business_submissions')
    .update(update)
    .eq('id', id);

  revalidatePath('/yonetici/isletme-basvurulari');
  return {};
}
