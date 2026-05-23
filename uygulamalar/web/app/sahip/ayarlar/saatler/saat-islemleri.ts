'use server';

import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { hasOwnerBusiness } from '@/src/lib/veri/owner/sahip-isletmeleri';
import { revalidatePath } from 'next/cache';

export async function saveHours(businessId: string, fd: FormData): Promise<void> {
  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) throw new Error('Kimlik doğrulaması gerekli');

  const canManageBusiness = await hasOwnerBusiness(supabase as any, user.id, businessId);
  if (!canManageBusiness) throw new Error('İşletme bulunamadı');

  const days = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];
  const payload: Record<string, string | null> = { business_id: businessId };
  for (const day of days) {
    const open = (fd.get(`${day}_open`) as string | null)?.trim() || null;
    const close = (fd.get(`${day}_close`) as string | null)?.trim() || null;
    payload[`${day}_open`] = open;
    payload[`${day}_close`] = close;
  }

  await (supabase as any)
    .from('business_hours')
    .upsert(payload, { onConflict: 'business_id' });

  revalidatePath('/sahip/ayarlar/saatler');
}
