'use server';

import { revalidatePath } from 'next/cache';
import { createSupabaseServerClient } from '@/src/lib/supabaseServer';

export async function updateReservationStatus(
  id: string,
  businessId: string,
  status: 'pending' | 'confirmed' | 'cancelled' | 'completed',
  ownerNote?: string,
): Promise<{ error?: string }> {
  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return { error: 'Oturum açmanız gerekiyor.' };

  const { error } = await (supabase as any).rpc('owner_update_reservation_status_v1', {
    p_id: id,
    p_business_id: businessId,
    p_status: status,
    p_owner_note: ownerNote ?? null,
  });

  if (error) return { error: error.message ?? 'Güncelleme başarısız.' };
  revalidatePath('/owner/reservations');
  return {};
}
