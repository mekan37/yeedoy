'use server';

import { revalidatePath } from 'next/cache';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';

export async function closeLeadAction(formData: FormData) {
  const id = String(formData.get('id') ?? '');
  const currentStatus = String(formData.get('currentStatus') ?? 'new');
  if (!id) return;

  const supabase = await createSupabaseServerClient();
  const sb = supabase as unknown as { rpc: (fn: string, args: Record<string, unknown>) => any };

  await sb.rpc('admin_update_sponsorship_lead_status_v1', {
    p_id: id,
    p_status: 'closed',
  });

  revalidatePath(`/yonetici/sponsor-adaylari?status=${currentStatus}`);
  revalidatePath('/yonetici/sponsor-adaylari');
}
