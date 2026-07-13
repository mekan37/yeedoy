'use server';

import { z } from 'zod';
import { revalidatePath } from 'next/cache';
import { createSupabaseServerClient } from '@/src/lib/supabaseServer';
import { createSupabaseServiceClient } from '@/src/lib/supabase/service';
import { canManageBusiness } from '@/src/lib/qr-access';

const UpdateBusinessSchema = z.object({
  name:                    z.string().min(1).max(120),
  category:                z.string().min(1).max(80),
  description:             z.string().max(1000).optional(),
  phone:                   z.string().max(30).optional(),
  address:                 z.string().max(300).optional(),
  reservation_url:         z.string().url().max(500).optional().or(z.literal('')),
  order_yemeksepeti_url:   z.string().url().max(500).optional().or(z.literal('')),
  order_trendyolgo_url:    z.string().url().max(500).optional().or(z.literal('')),
  order_getir_url:         z.string().url().max(500).optional().or(z.literal('')),
});

export async function updateBusiness(
  businessId: string,
  formData: FormData,
): Promise<{ error: string } | null> {
  const raw = {
    name:                  formData.get('name'),
    category:              formData.get('category'),
    description:           formData.get('description') || undefined,
    phone:                 formData.get('phone') || undefined,
    address:               formData.get('address') || undefined,
    reservation_url:       formData.get('reservation_url') ?? '',
    order_yemeksepeti_url: formData.get('order_yemeksepeti_url') ?? '',
    order_trendyolgo_url:  formData.get('order_trendyolgo_url') ?? '',
    order_getir_url:       formData.get('order_getir_url') ?? '',
  };

  const parsed = UpdateBusinessSchema.safeParse(raw);
  if (!parsed.success) {
    return { error: 'Geçersiz form verisi' };
  }

  // Yetki kontrolü: can_manage_business_v1 RPC (owner_claims tablosuna bakar)
  const canManage = await canManageBusiness(businessId);
  if (!canManage) return { error: 'Bu işletmeyi düzenleme yetkiniz yok' };

  const service = createSupabaseServiceClient();
  if (!service) return { error: 'Servis bağlantısı kurulamadı' };

  const toNull = (v: string | undefined) => (v && v.trim() !== '' ? v.trim() : null);

  const { error } = await (service as any)
    .from('businesses')
    .update({
      name:                    parsed.data.name,
      category:                parsed.data.category,
      description:             toNull(parsed.data.description),
      phone:                   toNull(parsed.data.phone),
      address:                 toNull(parsed.data.address),
      reservation_url:         toNull(parsed.data.reservation_url),
      order_yemeksepeti_url:   toNull(parsed.data.order_yemeksepeti_url),
      order_trendyolgo_url:    toNull(parsed.data.order_trendyolgo_url),
      order_getir_url:         toNull(parsed.data.order_getir_url),
    })
    .eq('id', businessId) as { error: { message: string } | null };

  if (error) return { error: error.message };

  revalidatePath(`/owner/businesses/${businessId}`);
  revalidatePath('/owner/businesses');
  return null;
}

export async function updateMealCardProviders(
  businessId: string,
  keys: string[],
): Promise<{ error: string } | null> {
  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return { error: 'Oturum bulunamadı' };

  const { error } = await (supabase as any).rpc(
    'owner_update_business_meal_card_providers_v1',
    { p_business_id: businessId, p_provider_keys: keys },
  ) as { error: { message: string } | null };

  if (error) return { error: error.message };

  revalidatePath(`/owner/businesses/${businessId}`);
  return null;
}
