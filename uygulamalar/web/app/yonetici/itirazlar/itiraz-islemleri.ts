'use server';

import { revalidatePath } from 'next/cache';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';

export async function decideAppeal(appealId: string, decision: 'approved' | 'rejected') {
  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return;

  await (supabase)
    .from('moderation_appeals')
    .update({ status: decision, decided_by: user.id, decided_at: new Date().toISOString() })
    .eq('id', appealId);

  revalidatePath('/yonetici/itirazlar');
}

export async function setAppealReview(appealId: string, inReview: boolean) {
  const supabase = await createSupabaseServerClient();
  const { data, error } = await (supabase).rpc('admin_set_appeal_review_v1', {
    p_appeal_id: appealId,
    p_in_review: inReview,
  }) as { data: { ok: boolean } | null; error: { message: string } | null };
  if (error || !data?.ok) throw new Error('İşlem gerçekleştirilemedi.');
  revalidatePath('/yonetici/itirazlar');
}
