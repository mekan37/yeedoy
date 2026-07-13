'use server';

import { revalidatePath } from 'next/cache';
import { createSupabaseServerClient } from '@/src/lib/supabaseServer';

export async function createMenu(
  businessId: string,
  title: string,
): Promise<{ menuId: string } | { error: string }> {
  if (!title.trim()) return { error: 'Menü adı boş olamaz' };

  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return { error: 'Oturum bulunamadı' };

  // Sahiplik doğrulaması
  const { data: claim } = await (supabase as any)
    .from('owner_claims')
    .select('id')
    .eq('user_id', user.id)
    .eq('business_id', businessId)
    .eq('status', 'approved')
    .maybeSingle() as { data: { id: string } | null };

  if (!claim) return { error: 'Bu işletme için yetkiniz yok' };

  const { data: menu, error } = await (supabase as any)
    .from('menus')
    .insert({ business_id: businessId, title: title.trim(), status: 'draft' })
    .select('id')
    .single() as { data: { id: string } | null; error: any };

  if (error) return { error: error.message };
  if (!menu) return { error: 'Menü oluşturulamadı' };

  revalidatePath('/owner/menus');
  return { menuId: menu.id };
}
