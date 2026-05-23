'use server';

import { revalidatePath } from 'next/cache';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';

export async function reviewAppeal(formData: FormData) {
  const id       = String(formData.get('id') ?? '');
  const decision = String(formData.get('decision') ?? '');
  const status   = String(formData.get('status') ?? 'pending');

  if (!id || !['approved', 'rejected'].includes(decision)) return;

  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return;

  await (supabase as any)
    .from('moderation_appeals')
    .update({
      status:       decision,
      decided_by:   user.id,
      decided_at:   new Date().toISOString(),
    })
    .eq('id', id);

  revalidatePath(`/yonetici/itirazlar?status=${status}`);
}
