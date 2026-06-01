'use server';

import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { revalidatePath } from 'next/cache';

export type LeadFormState = {
  ok: boolean;
  error?: string;
  message?: string;
};

export async function sponsorluguBasvur(
  prevState: LeadFormState,
  formData: FormData
): Promise<LeadFormState> {
  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return { ok: false, error: 'Oturum gerekli' };

  const businessId = formData.get('business_id') as string | null;
  const phone = (formData.get('phone') as string | null)?.trim() || null;
  const message = (formData.get('message') as string | null)?.trim() || null;

  if (!businessId) return { ok: false, error: 'İşletme seçimi zorunlu' };

  const { data, error } = await (supabase as any).rpc('submit_sponsorship_lead_v1', {
    p_business_id: businessId,
    p_phone: phone,
    p_message: message,
    p_preferred_surface: 'discovery',
    p_preferred_targeting: {},
  });

  if (error || !data?.ok) {
    return { ok: false, error: data?.message ?? error?.message ?? 'Bir hata oluştu' };
  }

  revalidatePath('/sahip/sponsorluk');
  return { ok: true, message: 'Başvurunuz alındı! Yeedoy ekibi en kısa sürede sizinle iletişime geçecek.' };
}
