'use server';

import { revalidatePath } from 'next/cache';
import { withAdminAuth } from '@/src/lib/sunucu-eylem-kimlik-dogrulama';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';

async function updateLeadStatus(id: string, newStatus: string): Promise<void> {
  if (!id) return;
  const supabase = await createSupabaseServerClient();
  const sb = supabase as unknown as { rpc: (fn: string, args: Record<string, unknown>) => unknown };
  await sb.rpc('admin_update_sponsorship_lead_status_v1', {
    p_id: id,
    p_status: newStatus,
  });
}

export async function markLeadContacted(formData: FormData): Promise<void> {
  const id = String(formData.get('id') ?? '');
  const currentStatus = String(formData.get('currentStatus') ?? 'new');
  if (!id) return;

  await withAdminAuth(async () => {
    await updateLeadStatus(id, 'contacted');
  });

  revalidatePath(`/yonetici/sponsor-adaylari?status=${currentStatus}`);
  revalidatePath('/yonetici/sponsor-adaylari');
}
