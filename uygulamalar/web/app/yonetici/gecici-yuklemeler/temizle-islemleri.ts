'use server';

import { revalidatePath } from 'next/cache';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { logger } from '@/src/lib/kayitci';

export async function surescDolanlariTemizle(): Promise<{ deleted?: number; error?: string }> {
  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return { error: 'Yetkisiz' };

  const { data: isAdmin } = await (supabase).rpc('is_admin');
  if (!isAdmin) return { error: 'Yetkisiz' };

  const { data, error } = await (supabase)
    .from('temp_uploads')
    .delete()
    .lt('expires_at', new Date().toISOString())
    .select('id');

  if (error) {
    // Ham Postgres hata mesajı doğrudan istemciye dönüyordu (şema/kolon
    // detayları sızdırabilir). Sunucu tarafında loglanıp genel mesaj dönülüyor.
    logger.error('gecici-yuklemeler/temizle: DB hatası', { message: error.message });
    return { error: 'Temizleme işlemi başarısız oldu.' };
  }

  const deletedCount = (data ?? []).length;
  await (supabase as any).rpc('log_admin_action_v1', {
    p_action: 'temp_uploads.cleanup',
    p_target_table: 'temp_uploads',
    p_target_id: null,
    p_meta: { deleted: deletedCount },
  });

  revalidatePath('/yonetici/gecici-yuklemeler');
  return { deleted: deletedCount };
}
