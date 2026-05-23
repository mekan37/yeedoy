'use server';

import { z } from 'zod';
import { redirect } from 'next/navigation';
import { createSupabaseServerClient } from '@/src/lib/supabaseServer';

const Schema = z.object({
  name: z.string().min(1).max(120),
  category: z.string().min(1).max(80),
  city: z.string().min(1).max(80),
  district: z.string().min(1).max(80),
  address: z.string().min(1).max(300),
  phone: z.string().max(30).optional(),
  website: z.string().url().max(500).optional().or(z.literal('')),
});

export async function submitNewBusiness(
  _prev: { error: string } | null,
  formData: FormData,
): Promise<{ error: string } | null> {
  const parsed = Schema.safeParse({
    name: formData.get('name'),
    category: formData.get('category'),
    city: formData.get('city'),
    district: formData.get('district'),
    address: formData.get('address'),
    phone: formData.get('phone') || undefined,
    website: formData.get('website') || undefined,
  });

  if (!parsed.success) {
    return { error: 'Lütfen zorunlu alanları doldurun.' };
  }

  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return { error: 'Oturum bulunamadı.' };

  const { data, error } = await supabase.rpc('owner_submit_new_business_v1', {
    p_name: parsed.data.name,
    p_city: parsed.data.city,
    p_district: parsed.data.district,
    p_category: parsed.data.category,
    p_address: parsed.data.address,
    p_phone: parsed.data.phone ?? null,
    p_website: parsed.data.website || null,
  } as never);

  if (error) return { error: error.message };

  const result = data as { ok: boolean; error?: string; request_id?: string };
  if (!result?.ok) return { error: result?.error ?? 'Başvuru gönderilemedi.' };

  redirect('/owner/businesses/submissions');
}
