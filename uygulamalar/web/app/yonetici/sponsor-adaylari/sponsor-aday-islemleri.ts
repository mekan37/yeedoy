'use server';

import { revalidatePath } from 'next/cache';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';

export async function markLeadContacted(formData: FormData) {
  const id            = String(formData.get('id') ?? '');
  const currentStatus = String(formData.get('currentStatus') ?? 'new');
  if (!id) return;

  const supabase = await createSupabaseServerClient();
  await (supabase as any)
    .from('sponsorship_leads')
    .update({ status: 'contacted' })
    .eq('id', id);

  revalidatePath(`/yonetici/sponsor-adaylari?status=${currentStatus}`);
}
