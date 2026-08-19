'use server';

import { z } from 'zod';
import { revalidatePath } from 'next/cache';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { rateLimit } from '@/src/lib/oran-siniri';

export type ActionState = { error: string } | { success: true } | null;

const KisiselBilgilerSchema = z.object({
  display_name: z.string().min(1).max(100),
  phone: z.string().max(30).optional(),
  birth_date: z.string().max(10).optional(),
  gender: z.string().max(30).optional(),
  bio: z.string().max(250).optional(),
});

export async function updateKisiselBilgiler(
  _previousState: ActionState,
  formData: FormData,
): Promise<ActionState> {
  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return { error: 'Oturum açmanız gerekiyor.' };

  const rl = rateLimit(`profilim-kisisel-bilgi:${user.id}`, 10, 60_000);
  if (!rl.ok) return { error: 'Çok fazla istek gönderildi. Lütfen bir süre sonra tekrar deneyin.' };

  const parsed = KisiselBilgilerSchema.safeParse({
    display_name: formData.get('display_name') ?? '',
    phone: formData.get('phone') ?? '',
    birth_date: formData.get('birth_date') ?? '',
    gender: formData.get('gender') ?? '',
    bio: formData.get('bio') ?? '',
  });
  if (!parsed.success) return { error: 'Lütfen bilgileri kontrol edin.' };

  const d = parsed.data;
  const { error } = await (supabase as any)
    .from('user_profiles')
    .update({
      display_name: d.display_name.trim(),
      phone: d.phone?.trim() || null,
      birth_date: d.birth_date?.trim() || null,
      gender: d.gender?.trim() || null,
      bio: d.bio?.trim() || null,
      updated_at: new Date().toISOString(),
    })
    .eq('user_id', user.id);

  if (error) return { error: 'Bilgileriniz güncellenemedi. Lütfen tekrar deneyin.' };

  revalidatePath('/sahip/profilim');
  return { success: true };
}
