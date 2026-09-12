'use server';

import { z } from 'zod';
import { headers } from 'next/headers';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { rateLimit, getClientIp } from '@/src/lib/rate-limit';

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
  const h = await headers();
  const ip = getClientIp(h) ?? 'unknown';
  const rl = await rateLimit(`reservation:${ip}`, 5, 60_000);
  if (!rl.ok) {
    return { error: 'Çok fazla istek gönderildi. Lütfen bir dakika bekleyin.' };
  }

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

  // create_reservation_v1 kimliksiz (anon) çağrılabiliyor ve kendi içinde
  // rate-limit yapmıyor — yalnızca IP'ye dayalı üstteki limit rotasyonlu
  // proxy/VPN ile kolayca aşılabilir. İşletme ve telefon başına ikinci bir
  // kova ekleyerek tek bir hedefin (ya da tek bir kimliğin) IP'den bağımsız
  // spam edilmesi engelleniyor — login rate-limit'inde (S-3) kurulan aynı
  // "IP + ikincil kimlik" deseni.
  const bizRl = await rateLimit(`reservation:biz:${d.business_id}`, 20, 60_000);
  if (!bizRl.ok) {
    return { error: 'Bu işletme için çok fazla rezervasyon isteği gönderildi. Lütfen bir dakika bekleyin.' };
  }
  const normalizedPhone = d.guest_phone.replace(/\D/g, '');
  const phoneRl = await rateLimit(`reservation:phone:${normalizedPhone}`, 3, 60_000);
  if (!phoneRl.ok) {
    return { error: 'Çok fazla istek gönderildi. Lütfen bir dakika bekleyin.' };
  }
  const supabase = await createSupabaseServerClient();

  const { data, error } = await (supabase).rpc('create_reservation_v1', {
    p_business_id: d.business_id,
    p_guest_name: d.guest_name,
    p_guest_phone: d.guest_phone,
    p_guest_email: d.guest_email || undefined,
    p_party_size: d.party_size,
    p_date: d.reservation_date,
    p_time: d.reservation_time,
    p_channel: 'web',
    p_special_request: d.special_request || undefined,
  });

  if (error) {
    const msg = error.message ?? '';
    if (msg.includes('validation_error:')) {
      return { error: msg.replace(/^validation_error:\s*/, '') };
    }
    return { error: 'Rezervasyon oluşturulamadı. Lütfen tekrar deneyin.' };
  }

  const result = data as { id: string; reservation_no: string } | null;
  return { success: true, reservationNo: result?.reservation_no };
}
