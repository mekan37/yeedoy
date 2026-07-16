'use server';

import { z } from 'zod';
import { revalidatePath } from 'next/cache';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { rateLimit } from '@/src/lib/rate-limit';

const REVALIDATE = '/sahip/pazarlama/kampanyalar';

const KampanyaSchema = z.object({
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

const SilKampanyaSchema = z.object({
  id:         z.string().uuid(),
  businessId: z.string().uuid(),
});

/** `<input type="datetime-local">` değeri ("YYYY-MM-DDTHH:mm") tam ISO 8601'e çevrilir. */
function datetimeLocalToIso(value: FormDataEntryValue | null): string | null {
  if (!value || typeof value !== 'string') return null;
  const d = new Date(value);
  return Number.isNaN(d.getTime()) ? null : d.toISOString();
}

export async function kaydetKampanya(
  _prev: { error: string } | null,
  formData: FormData,
): Promise<{ error: string } | null> {
  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return { error: 'Oturum açmanız gerekiyor.' };

  const rl = rateLimit(`owner-campaign-upsert:${user.id}`, 20, 60_000);
  if (!rl.ok) return { error: 'Çok fazla istek gönderildi. Lütfen bir dakika bekleyin.' };

  const raw = {
    business_id:      formData.get('business_id'),
    title:            formData.get('title'),
    type:             formData.get('type'),
    status:           formData.get('status'),
    description:      formData.get('description') || undefined,
    discount_percent: formData.get('discount_percent') || null,
    starts_at:        datetimeLocalToIso(formData.get('starts_at')),
    ends_at:          datetimeLocalToIso(formData.get('ends_at')),
    id:               formData.get('id') || null,
  };

  const parsed = KampanyaSchema.safeParse(raw);
  if (!parsed.success) return { error: 'Geçersiz form verisi' };

  const d = parsed.data;
  const { error } = await (supabase as any).rpc('owner_upsert_campaign_v1', {
    p_business_id:      d.business_id,
    p_title:            d.title,
    p_type:             d.type,
    p_status:           d.status,
    p_description:      d.description ?? null,
    p_discount_percent: d.discount_percent ?? null,
    p_starts_at:        d.starts_at ?? null,
    p_ends_at:          d.ends_at ?? null,
    p_id:               d.id ?? null,
  }) as { error: { message: string } | null };

  if (error) return { error: error.message };
  revalidatePath(REVALIDATE);
  return null;
}

export async function silKampanya(
  id: string,
  businessId: string,
): Promise<{ error: string } | null> {
  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return { error: 'Oturum açmanız gerekiyor.' };

  const rl = rateLimit(`owner-campaign-delete:${user.id}`, 20, 60_000);
  if (!rl.ok) return { error: 'Çok fazla istek gönderildi. Lütfen bir dakika bekleyin.' };

  const parsed = SilKampanyaSchema.safeParse({ id, businessId });
  if (!parsed.success) return { error: 'Geçersiz istek parametreleri.' };

  const d = parsed.data;
  const { error } = await (supabase as any).rpc('owner_delete_campaign_v1', {
    p_id:          d.id,
    p_business_id: d.businessId,
  }) as { error: { message: string } | null };

  if (error) return { error: error.message };
  revalidatePath(REVALIDATE);
  return null;
}
