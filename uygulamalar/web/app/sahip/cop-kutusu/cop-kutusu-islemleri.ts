'use server';

import { revalidatePath } from 'next/cache';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { withAuth } from '@/src/lib/sunucu-eylem-kimlik-dogrulama';

export async function restoreMenu(menuId: string): Promise<{ error?: string }> {
  return withAuth(async () => {
    const supabase = await createSupabaseServerClient();
    const { error } = await (supabase as any).rpc('owner_restore_menu_v1', { p_menu_id: menuId });
    if (error) return { error: error.message };
    revalidatePath('/sahip/cop-kutusu');
    revalidatePath('/sahip/menuler');
    return {};
  });
}

export async function restoreItem(itemId: string): Promise<{ error?: string }> {
  return withAuth(async () => {
    const supabase = await createSupabaseServerClient();
    const { error } = await (supabase as any).rpc('owner_restore_menu_item_v1', { p_item_id: itemId });
    if (error) return { error: error.message };
    revalidatePath('/sahip/cop-kutusu');
    return {};
  });
}

export async function restorePhoto(photoId: string): Promise<{ error?: string }> {
  return withAuth(async () => {
    const supabase = await createSupabaseServerClient();
    const { error } = await (supabase as any).rpc('owner_restore_menu_item_photo_v1', { p_photo_id: photoId });
    if (error) return { error: error.message };
    revalidatePath('/sahip/cop-kutusu');
    return {};
  });
}

export async function permanentlyDeleteMenu(menuId: string): Promise<{ error?: string }> {
  return withAuth(async () => {
    const supabase = await createSupabaseServerClient();
    const { error } = await (supabase as any).rpc('owner_permanently_delete_menu_v1', { p_menu_id: menuId });
    if (error) return { error: error.message };
    revalidatePath('/sahip/cop-kutusu');
    return {};
  });
}

export async function permanentlyDeleteItem(itemId: string): Promise<{ error?: string }> {
  return withAuth(async () => {
    const supabase = await createSupabaseServerClient();
    const { error } = await (supabase as any).rpc('owner_permanently_delete_menu_item_v1', { p_item_id: itemId });
    if (error) return { error: error.message };
    revalidatePath('/sahip/cop-kutusu');
    return {};
  });
}

export async function permanentlyDeletePhoto(photoId: string): Promise<{ error?: string }> {
  return withAuth(async () => {
    const supabase = await createSupabaseServerClient();
    const { error } = await (supabase as any).rpc('owner_permanently_delete_menu_item_photo_v1', { p_photo_id: photoId });
    if (error) return { error: error.message };
    revalidatePath('/sahip/cop-kutusu');
    return {};
  });
}

export async function emptyTrash(businessId: string): Promise<{ error?: string }> {
  return withAuth(async () => {
    const supabase = await createSupabaseServerClient();
    const { error } = await (supabase as any).rpc('owner_empty_trash_v1', { p_business_id: businessId });
    if (error) return { error: error.message };
    revalidatePath('/sahip/cop-kutusu');
    return {};
  });
}
