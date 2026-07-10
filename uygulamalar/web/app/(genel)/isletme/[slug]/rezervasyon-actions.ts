'use server';

import { z } from 'zod';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';

const schema = z.object({
  business_id: z.string().uuid(),
  guest_name: z.string().min(2).max(100),
  guest_phone: z.string().min(10).max(20),
  guest_email: z.string().email().optional().or(z.literal('')),
  party_size: z.coerce.number().int().min(1).max(100),
  reservation_date: z.string().regex(/^\d{4}-\d{2}-\d{2}$/),
  reservation_time: z.string().regex(/^\d{2}:\d{2}$/),
  special_request: z.string().max(500).optional(),
});

export async function submitReservation(
  _prev: { error?: string; success?: boolean; reservationNo?: string } | null,
  formData: FormData,
): Promise<{ error?: string; success?: boolean; reservationNo?: string }> {
  const parsed = schema.safeParse({
    business_id: formData.get('business_id'),
    guest_name: formData.get('guest_name'),
    guest_phone: formData.get('guest_phone'),
    guest_email: formData.get('guest_email') || undefined,
    party_size: formData.get('party_size'),
    reservation_date: formData.get('reservation_date'),
    reservation_time: formData.get('reservation_time'),
    special_request: formData.get('special_request') || undefined,
  });

  if (!parsed.success) {
    return { error: 'Lütfen tüm zorunlu alanları doğru doldurun.' };
  }

  const d = parsed.data;
  const supabase = await createSupabaseServerClient();

  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const { data, error } = await (supabase as any).rpc('create_reservation_v1', {
    p_business_id: d.business_id,
    p_guest_name: d.guest_name,
    p_guest_phone: d.guest_phone,
    p_guest_email: d.guest_email || null,
    p_party_size: d.party_size,
    p_date: d.reservation_date,
    p_time: d.reservation_time,
    p_channel: 'web',
    p_special_request: d.special_request || null,
  });

  if (error) {
    const msg = error.message ?? '';
    if (msg.includes('validation_error:')) {
      return { error: msg.replace('validation_error: ', '') };
    }
    return { error: 'Rezervasyon oluşturulamadı. Lütfen tekrar deneyin.' };
  }

  const result = data as { id: string; reservation_no: string } | null;
  return { success: true, reservationNo: result?.reservation_no };
}
