'use server';

import { revalidatePath } from 'next/cache';
import { createSupabaseServerClient } from '@/src/lib/supabaseServer';

async function assertAdmin() {
  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return { error: 'Unauthorized', supabase: null };

  const { data: profile } = await (supabase as any)
    .from('user_profiles')
    .select('role')
    .eq('id', user.id)
    .single();

  const adminRoles = ['super_admin', 'admin', 'community_mod'];
  if (!profile || !adminRoles.includes(profile.role)) {
    return { error: 'Unauthorized', supabase: null };
  }

  return { error: null, supabase };
}

export async function approveSubmission(id: string): Promise<{ error?: string }> {
  const { error, supabase } = await assertAdmin();
  if (error || !supabase) return { error: error ?? 'Unauthorized' };

  await (supabase as any)
    .from('business_submissions')
    .update({ status: 'approved' })
    .eq('id', id);

  revalidatePath('/admin/business-submissions');
  return {};
}

export async function rejectSubmission(
  id: string,
  reason?: string,
): Promise<{ error?: string }> {
  const { error, supabase } = await assertAdmin();
  if (error || !supabase) return { error: error ?? 'Unauthorized' };

  const update: Record<string, string> = { status: 'rejected' };
  if (reason?.trim()) update.admin_note = reason.trim();

  await (supabase as any)
    .from('business_submissions')
    .update(update)
    .eq('id', id);

  revalidatePath('/admin/business-submissions');
  return {};
}
