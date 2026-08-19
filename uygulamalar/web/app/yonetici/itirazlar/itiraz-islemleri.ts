'use server';

import { revalidatePath } from 'next/cache';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';

export async function decideAppeal(appealId: string, decision: 'approved' | 'rejected') {
  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return;

  await (supabase as any)
    .from('moderation_appeals')
    .update({ status: decision, decided_by: user.id, decided_at: new Date().toISOString() })
    .eq('id', appealId);

  revalidatePath('/yonetici/itirazlar');
}

export async function setAppealReview(appealId: string, inReview: boolean) {
  const supabase = await createSupabaseServerClient();
  const { data, error } = await (supabase as any).rpc('admin_set_appeal_review_v1', {
    p_appeal_id: appealId,
    p_in_review: inReview,
  });
  if (error || !data?.ok) throw new Error('İşlem gerçekleştirilemedi.');
  revalidatePath('/yonetici/itirazlar');
}
