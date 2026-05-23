'use server';

import { revalidatePath } from 'next/cache';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';

export async function surescDolanlariTemizle(): Promise<{ deleted?: number; error?: string }> {
  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return { error: 'Yetkisiz' };

  const { data: isAdmin } = await (supabase as any).rpc('is_admin');
  if (!isAdmin) return { error: 'Yetkisiz' };

  const { data, error } = await (supabase as any)
    .from('temp_uploads')
    .delete()
    .lt('expires_at', new Date().toISOString())
    .select('id');

  if (error) return { error: error.message };
  revalidatePath('/yonetici/gecici-yuklemeler');
  return { deleted: (data ?? []).length };
}
