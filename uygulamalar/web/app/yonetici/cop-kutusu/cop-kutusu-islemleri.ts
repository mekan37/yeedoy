'use server';

import { revalidatePath } from 'next/cache';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';

async function logAudit(supabase: any, action: string, menuId: string) {
  await supabase
    .rpc('log_admin_action_v1', { p_action: action, p_target_table: 'menus', p_target_id: menuId })
    .then(() => {})
    .catch(() => {});
}

export async function adminRestoreMenu(menuId: string): Promise<{ error?: string }> {
  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return { error: 'Yetkisiz' };

  const { data, error } = await (supabase as any).rpc('owner_restore_menu_v1', { p_menu_id: menuId });
  if (error || !data?.ok) return { error: data?.code ?? error?.message ?? 'Geri yüklenemedi' };

  await logAudit(supabase, 'restore', menuId);
  revalidatePath('/yonetici/cop-kutusu');
  return {};
}

export async function adminPermanentlyDeleteMenu(menuId: string): Promise<{ error?: string }> {
  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return { error: 'Yetkisiz' };

  const { data, error } = await (supabase as any).rpc('owner_permanently_delete_menu_v1', { p_menu_id: menuId });
  if (error || !data?.ok) return { error: data?.code ?? error?.message ?? 'Kalıcı silinemedi' };

  await logAudit(supabase, 'delete', menuId);
  revalidatePath('/yonetici/cop-kutusu');
  return {};
}
