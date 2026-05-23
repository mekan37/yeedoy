'use server';

import { revalidatePath } from 'next/cache';
import { createSupabaseServerClient } from '@/src/lib/supabaseServer';
import { withAuth } from '@/src/lib/server-action-auth';

export async function restoreMenu(menuId: string): Promise<{ error?: string }> {
  return withAuth(async () => {
    const supabase = await createSupabaseServerClient();
    const { error } = await (supabase as any).rpc('owner_restore_menu_v1', { p_menu_id: menuId });
    if (error) return { error: error.message };
    revalidatePath('/owner/trash');
    revalidatePath('/owner/menus');
    return {};
  });
}

export async function restoreItem(itemId: string): Promise<{ error?: string }> {
  return withAuth(async () => {
    const supabase = await createSupabaseServerClient();
    const { error } = await (supabase as any).rpc('owner_restore_menu_item_v1', { p_item_id: itemId });
    if (error) return { error: error.message };
    revalidatePath('/owner/trash');
    return {};
  });
}

export async function restorePhoto(photoId: string): Promise<{ error?: string }> {
  return withAuth(async () => {
    const supabase = await createSupabaseServerClient();
    const { error } = await (supabase as any).rpc('owner_restore_menu_item_photo_v1', { p_photo_id: photoId });
    if (error) return { error: error.message };
    revalidatePath('/owner/trash');
    return {};
  });
}
