'use server';

import { z } from 'zod';
import { revalidatePath } from 'next/cache';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { withAuth } from '@/src/lib/sunucu-eylem-kimlik-dogrulama';
import { rateLimit } from '@/src/lib/oran-siniri';

const REVALIDATE_PREFIX = '/sahip/musteriler';

type EylemSonucu = { error: string } | { ok: true };

const NotEkleSemasi = z.object({
  business_id: z.string().uuid(),
  user_id: z.string().uuid(),
  note: z.string().min(1).max(1000),
});

export async function notEkle(businessId: string, userId: string, note: string): Promise<EylemSonucu> {
  const parsed = NotEkleSemasi.safeParse({ business_id: businessId, user_id: userId, note });
  if (!parsed.success) return { error: 'Geçersiz form verisi' };
  const d = parsed.data;

  return withAuth(async (ownerId) => {
    const limitResult = rateLimit(`musteri-not-ekle:${ownerId}`, 20, 60_000);
    if (!limitResult.ok) return { error: 'Çok fazla istek gönderildi. Lütfen daha sonra tekrar deneyin.' };

    const supabase = await createSupabaseServerClient();
    const { error } = (await (supabase as any).rpc('add_customer_note_v1', {
      p_business_id: d.business_id,
      p_user_id: d.user_id,
      p_note: d.note,
    })) as { error: { message: string } | null };

    if (error) return { error: error.message };
    revalidatePath(`${REVALIDATE_PREFIX}/${d.user_id}`);
    return { ok: true };
  });
}

const EtiketEkleSemasi = z.object({
  business_id: z.string().uuid(),
  user_id: z.string().uuid(),
  tag: z.string().min(1).max(40),
});

export async function etiketEkle(businessId: string, userId: string, tag: string): Promise<EylemSonucu> {
  const parsed = EtiketEkleSemasi.safeParse({ business_id: businessId, user_id: userId, tag });
  if (!parsed.success) return { error: 'Geçersiz form verisi' };
  const d = parsed.data;

  return withAuth(async (ownerId) => {
    const limitResult = rateLimit(`musteri-etiket-ekle:${ownerId}`, 20, 60_000);
    if (!limitResult.ok) return { error: 'Çok fazla istek gönderildi. Lütfen daha sonra tekrar deneyin.' };

    const supabase = await createSupabaseServerClient();
    const { error } = (await (supabase as any).rpc('add_customer_tag_v1', {
      p_business_id: d.business_id,
      p_user_id: d.user_id,
      p_tag: d.tag,
    })) as { error: { message: string } | null };

    if (error) return { error: error.message };
    revalidatePath(`${REVALIDATE_PREFIX}/${d.user_id}`);
    revalidatePath(REVALIDATE_PREFIX);
    return { ok: true };
  });
}

const EtiketSilSemasi = z.object({ tag_id: z.string().uuid(), user_id: z.string().uuid() });

export async function etiketSil(tagId: string, userId: string): Promise<EylemSonucu> {
  const parsed = EtiketSilSemasi.safeParse({ tag_id: tagId, user_id: userId });
  if (!parsed.success) return { error: 'Geçersiz parametre' };
  const d = parsed.data;

  return withAuth(async (ownerId) => {
    const limitResult = rateLimit(`musteri-etiket-sil:${ownerId}`, 20, 60_000);
    if (!limitResult.ok) return { error: 'Çok fazla istek gönderildi. Lütfen daha sonra tekrar deneyin.' };

    const supabase = await createSupabaseServerClient();
    const { error } = (await (supabase as any).rpc('remove_customer_tag_v1', {
      p_tag_id: d.tag_id,
    })) as { error: { message: string } | null };

    if (error) return { error: error.message };
    revalidatePath(`${REVALIDATE_PREFIX}/${d.user_id}`);
    revalidatePath(REVALIDATE_PREFIX);
    return { ok: true };
  });
}
