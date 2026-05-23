'use server';

import { revalidatePath } from 'next/cache';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';

export async function adminMenuGeriAl(menuId: string): Promise<{ error?: string }> {
  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return { error: 'Yetkisiz' };

  const { data: isAdmin } = await (supabase as any).rpc('is_admin');
  if (!isAdmin) return { error: 'Yetkisiz' };

  const { error } = await (supabase as any)
    .from('menus')
    .update({ deleted_at: null })
    .eq('id', menuId);

  if (error) return { error: error.message };
  revalidatePath('/yonetici/cop-kutusu');
  return {};
}
