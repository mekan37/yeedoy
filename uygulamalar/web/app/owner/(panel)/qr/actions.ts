'use server';

import { z } from 'zod';
import { revalidatePath } from 'next/cache';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';

const REVALIDATE = '/owner/qr';

const QrSchema = z.object({
  business_id: z.string().uuid(),
  name:        z.string().min(1).max(100),
  type:        z.enum(['dynamic_menu', 'static_menu', 'custom']),
  description: z.string().max(300).optional(),
  target_url:  z.string().url().optional().or(z.literal('')),
  language:    z.enum(['tr', 'en']).default('tr'),
  is_active:   z.coerce.boolean().default(true),
  id:          z.string().uuid().optional().nullable(),
});

export async function upsertQrCode(
  _prev: { error: string } | null,
  formData: FormData,
): Promise<{ error: string } | null> {
  const raw = {
    business_id: formData.get('business_id'),
    name:        formData.get('name'),
    type:        formData.get('type'),
    description: formData.get('description') || undefined,
    target_url:  formData.get('target_url') || undefined,
    language:    formData.get('language') || 'tr',
    is_active:   formData.get('is_active') !== 'false',
    id:          formData.get('id') || null,
  };

  const parsed = QrSchema.safeParse(raw);
  if (!parsed.success) return { error: 'Geçersiz form verisi' };

  const d = parsed.data;
  const supabase = await createSupabaseServerClient();
  const { error } = await (supabase as any).rpc('owner_upsert_qr_code_v1', {
    p_business_id: d.business_id,
    p_name:        d.name,
    p_type:        d.type,
    p_description: d.description ?? null,
    p_target_url:  d.target_url || null,
    p_language:    d.language,
    p_is_active:   d.is_active,
    p_id:          d.id ?? null,
  }) as { error: { message: string } | null };

  if (error) return { error: error.message };
  revalidatePath(REVALIDATE);
  return null;
}

export async function deleteQrCode(
  id: string,
  businessId: string,
): Promise<{ error: string } | null> {
  const supabase = await createSupabaseServerClient();
  const { error } = await (supabase as any).rpc('owner_delete_qr_code_v1', {
    p_id:          id,
    p_business_id: businessId,
  }) as { error: { message: string } | null };

  if (error) return { error: error.message };
  revalidatePath(REVALIDATE);
  return null;
}
