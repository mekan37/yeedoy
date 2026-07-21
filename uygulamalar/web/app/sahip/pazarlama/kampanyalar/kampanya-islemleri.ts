'use server';

import { z } from 'zod';
import { revalidatePath } from 'next/cache';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { withAuth } from '@/src/lib/sunucu-eylem-kimlik-dogrulama';

const REVALIDATE = '/sahip/pazarlama/kampanyalar';

const KampanyaSemasi = z.object({
  business_id:      z.string().uuid(),
  title:            z.string().min(1).max(120),
  type:             z.enum(['discount', 'special_offer', 'loyalty', 'announcement']),
  status:           z.enum(['draft', 'planned', 'active', 'completed']),
  description:      z.string().max(500).optional(),
  discount_percent: z.coerce.number().int().min(1).max(100).optional().nullable(),
  starts_at:        z.string().datetime().optional().nullable(),
  ends_at:          z.string().datetime().optional().nullable(),
  id:               z.string().uuid().optional().nullable(),
});

export async function kampanyaKaydet(
  _prev: { error: string } | null,
  formData: FormData,
): Promise<{ error: string } | null> {
  const raw = {
    business_id:      formData.get('business_id'),
    title:            formData.get('title'),
    type:             formData.get('type'),
    status:           formData.get('status'),
    description:      formData.get('description') || undefined,
    discount_percent: formData.get('discount_percent') || null,
    starts_at:        formData.get('starts_at') || null,
    ends_at:          formData.get('ends_at') || null,
    id:               formData.get('id') || null,
  };

  const parsed = KampanyaSemasi.safeParse(raw);
  if (!parsed.success) return { error: 'Geçersiz form verisi' };

  const d = parsed.data;

  return withAuth(async () => {
    const supabase = await createSupabaseServerClient();
    const { error } = await (supabase as any).rpc('owner_upsert_campaign_v1', {
      p_business_id:     d.business_id,
      p_title:           d.title,
      p_type:            d.type,
      p_status:          d.status,
      p_description:     d.description ?? null,
      p_discount_percent: d.discount_percent ?? null,
      p_starts_at:       d.starts_at ?? null,
      p_ends_at:         d.ends_at ?? null,
      p_id:              d.id ?? null,
    }) as { error: { message: string } | null };

    if (error) return { error: error.message };
    revalidatePath(REVALIDATE);
    return null;
  });
}

export async function kampanyaSil(
  id: string,
  businessId: string,
): Promise<{ error: string } | null> {
  return withAuth(async () => {
    const supabase = await createSupabaseServerClient();
    const { error } = await (supabase as any).rpc('owner_delete_campaign_v1', {
      p_id:          id,
      p_business_id: businessId,
    }) as { error: { message: string } | null };

    if (error) return { error: error.message };
    revalidatePath(REVALIDATE);
    return null;
  });
}
