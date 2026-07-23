'use server';

import { z } from 'zod';
import { revalidatePath } from 'next/cache';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { hasOwnerBusiness } from '@/src/lib/veri/owner/sahip-isletmeleri';

const UpdateBusinessSchema = z.object({
  name: z.string().min(1).max(120),
  category: z.string().min(1).max(80),
  description: z.string().max(1000).optional(),
  phone: z.string().max(30).optional(),
  address: z.string().max(500).optional(),
  city: z.string().max(100).optional(),
  district: z.string().max(100).optional(),
  neighborhood: z.string().max(120).optional(),
  lat: z.coerce.number().min(-90).max(90).optional(),
  lng: z.coerce.number().min(-180).max(180).optional(),
  logoUrl: z.string().url().max(1000).optional(),
  coverUrl: z.string().url().max(1000).optional(),
  reservationUrl: z.string().url().max(1000).optional(),
  orderYemeksepetiUrl: z.string().url().max(1000).optional(),
  orderTrendyolgoUrl: z.string().url().max(1000).optional(),
  orderGetirUrl: z.string().url().max(1000).optional(),
});

export async function updateBusiness(
  businessId: string,
  formData: FormData,
): Promise<{ error: string } | null> {
  const parsed = UpdateBusinessSchema.safeParse({
    name: formData.get('name'),
    category: formData.get('category'),
    description: formData.get('description') || undefined,
    phone: formData.get('phone') || undefined,
    address: formData.get('address') || undefined,
    city: formData.get('city') || undefined,
    district: formData.get('district') || undefined,
    neighborhood: formData.get('neighborhood') || undefined,
    lat: formData.get('lat') || undefined,
    lng: formData.get('lng') || undefined,
    logoUrl: formData.get('logoUrl') || undefined,
    coverUrl: formData.get('coverUrl') || undefined,
    reservationUrl: formData.get('reservationUrl') || undefined,
    orderYemeksepetiUrl: formData.get('orderYemeksepetiUrl') || undefined,
    orderTrendyolgoUrl: formData.get('orderTrendyolgoUrl') || undefined,
    orderGetirUrl: formData.get('orderGetirUrl') || undefined,
  });

  if (!parsed.success) {
    return { error: 'Geçersiz form verisi' };
  }

  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return { error: 'Oturum bulunamadı' };

  const canManageBusiness = await hasOwnerBusiness(supabase as any, user.id, businessId);
  if (!canManageBusiness) return { error: 'Yetkiniz yok' };

  const { error } = await (supabase as any)
    .from('businesses')
    .update({
      name: parsed.data.name,
      category: parsed.data.category,
      description: parsed.data.description ?? null,
      phone: parsed.data.phone ?? null,
      address: parsed.data.address ?? null,
      city: parsed.data.city ?? null,
      district: parsed.data.district ?? null,
      neighborhood: parsed.data.neighborhood ?? null,
      lat: parsed.data.lat ?? null,
      lng: parsed.data.lng ?? null,
      logo_url: parsed.data.logoUrl ?? null,
      cover_url: parsed.data.coverUrl ?? null,
      reservation_url: parsed.data.reservationUrl ?? null,
      order_yemeksepeti_url: parsed.data.orderYemeksepetiUrl ?? null,
      order_trendyolgo_url: parsed.data.orderTrendyolgoUrl ?? null,
      order_getir_url: parsed.data.orderGetirUrl ?? null,
    })
    .eq('id', businessId) as { error: { message: string } | null };

  if (error) return { error: error.message };

  revalidatePath(`/sahip/isletmeler/${businessId}`);
  revalidatePath('/sahip/isletmeler');
  return null;
}

export async function updateMealCardProviders(
  businessId: string,
  keys: string[],
): Promise<{ error: string } | null> {
  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return { error: 'Oturum bulunamadı' };

  const { data, error } = await (supabase as any).rpc(
    'owner_update_business_meal_card_providers_v1',
    { p_business_id: businessId, p_provider_keys: keys },
  ) as { data: { ok: boolean; code?: string; message?: string } | null; error: { message: string } | null };

  if (error) return { error: error.message };
  if (data?.ok === false) return { error: data.message ?? 'Güncellenemedi' };

  revalidatePath(`/sahip/isletmeler/${businessId}`);
  return null;
}
