'use server';

import { createSupabaseServerClient } from '@/src/lib/supabaseServer';
import { revalidatePath } from 'next/cache';

// day_of_week: 0=Pazar, 1=Pazartesi, ..., 6=Cumartesi (business_weekly_hours convention)
const DAY_MAP = [
  { fd: 'mon', dow: 1 },
  { fd: 'tue', dow: 2 },
  { fd: 'wed', dow: 3 },
  { fd: 'thu', dow: 4 },
  { fd: 'fri', dow: 5 },
  { fd: 'sat', dow: 6 },
  { fd: 'sun', dow: 0 },
] as const;

export async function saveHours(businessId: string, fd: FormData): Promise<void> {
  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) throw new Error('Kimlik doğrulaması gerekli');

  const hours = DAY_MAP.map(({ fd: key, dow }) => {
    const open = (fd.get(`${key}_open`) as string | null)?.trim() || null;
    const close = (fd.get(`${key}_close`) as string | null)?.trim() || null;
    const isClosed = !open || !close;
    return {
      day_of_week: dow,
      open_time: isClosed ? '09:00' : open,
      close_time: isClosed ? '22:00' : close,
      is_closed: isClosed,
    };
  });

  const { error } = await (supabase as any).rpc('upsert_business_hours_v1', {
    p_business_id: businessId,
    p_hours: hours,
  });

  if (error) throw new Error('Çalışma saatleri kaydedilemedi. Lütfen tekrar deneyin.');

  revalidatePath('/owner/settings/hours');
}
