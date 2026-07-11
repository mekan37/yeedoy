'use server';

import { z } from 'zod';
import { revalidatePath } from 'next/cache';
import { createSupabaseServerClient } from '@/src/lib/supabaseServer';
import { rateLimit } from '@/src/lib/rate-limit';

const UpdateStatusSchema = z.object({
  id:         z.string().uuid(),
  businessId: z.string().uuid(),
  status:     z.enum(['pending', 'confirmed', 'cancelled', 'completed', 'no_show']),
  ownerNote:  z.string().max(1000).nullish(),
});

export async function updateReservationStatus(
  id: string,
  businessId: string,
  status: 'pending' | 'confirmed' | 'cancelled' | 'completed' | 'no_show',
  ownerNote?: string | null,
): Promise<{ error?: string }> {
  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return { error: 'Oturum açmanız gerekiyor.' };

  const rl = rateLimit(`owner-reservation-status:${user.id}`, 20, 60_000);
  if (!rl.ok) return { error: 'Çok fazla istek gönderildi. Lütfen bir dakika bekleyin.' };

  const parsed = UpdateStatusSchema.safeParse({ id, businessId, status, ownerNote });
  if (!parsed.success) return { error: 'Geçersiz istek parametreleri.' };

  const d = parsed.data;
  const { error } = await (supabase as any).rpc('owner_update_reservation_status_v1', {
    p_id:          d.id,
    p_business_id: d.businessId,
    p_status:      d.status,
    p_owner_note:  d.ownerNote ?? null,
  });

  if (error) {
    const msg = error.message ?? '';
    if (msg.includes('not_found:') || msg.includes('unauthorized:') || msg.includes('validation_error:')) {
      return { error: msg.replace(/^(not_found|unauthorized|validation_error):\s*/, '') };
    }
    return { error: 'Güncelleme başarısız. Lütfen tekrar deneyin.' };
  }
  revalidatePath('/owner/reservations');
  return {};
}
