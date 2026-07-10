'use server';

import { z } from 'zod';
import { revalidatePath } from 'next/cache';
import { createSupabaseServerClient } from '@/src/lib/supabaseServer';

const UpdateBusinessSchema = z.object({
  name: z.string().min(1).max(120),
  category: z.string().min(1).max(80),
  description: z.string().max(1000).optional(),
  phone: z.string().max(30).optional(),
  address: z.string().max(300).optional(),
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
  });

  if (!parsed.success) {
    return { error: 'Geçersiz form verisi' };
  }

  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return { error: 'Oturum bulunamadı' };

  const { error } = await (supabase as any)
    .from('businesses')
    .update({
      name: parsed.data.name,
      category: parsed.data.category,
      description: parsed.data.description ?? null,
      phone: parsed.data.phone ?? null,
      address: parsed.data.address ?? null,
    })
    .eq('id', businessId)
    .eq('owner_id', user.id) as { error: { message: string } | null };

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
