'use server';

import { revalidatePath } from 'next/cache';
import { createSupabaseServerClient } from '@/src/lib/supabaseServer';

type ActionResult = { error: string } | null;

export async function updateMenuTitle(menuId: string, title: string): Promise<ActionResult> {
  if (!title.trim()) return { error: 'Başlık boş olamaz' };
  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return { error: 'Oturum bulunamadı' };
  const { error } = await (supabase as any).from('menus').update({ title: title.trim() }).eq('id', menuId);
  if (error) return { error: error.message };
  revalidatePath(`/owner/menus/${menuId}/edit`);
  return null;
}

export async function publishMenu(menuId: string, status: 'draft' | 'published' | 'archived'): Promise<ActionResult> {
  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return { error: 'Oturum bulunamadı' };
  const { error } = await (supabase as any).from('menus').update({ status }).eq('id', menuId);
  if (error) return { error: error.message };
  revalidatePath(`/owner/menus/${menuId}/edit`);
  revalidatePath('/owner/menus');
  return null;
}

export async function createSection(menuId: string, title: string, sortOrder: number): Promise<ActionResult> {
  if (!title.trim()) return { error: 'Bölüm adı boş olamaz' };
  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return { error: 'Oturum bulunamadı' };
  const { error } = await (supabase as any).from('menu_sections').insert({ menu_id: menuId, title: title.trim(), sort_order: sortOrder });
  if (error) return { error: error.message };
  revalidatePath(`/owner/menus/${menuId}/edit`);
  return null;
}

export async function updateSection(sectionId: string, menuId: string, title: string): Promise<ActionResult> {
  if (!title.trim()) return { error: 'Bölüm adı boş olamaz' };
  const supabase = await createSupabaseServerClient();
  const { error } = await (supabase as any).from('menu_sections').update({ title: title.trim() }).eq('id', sectionId);
  if (error) return { error: error.message };
  revalidatePath(`/owner/menus/${menuId}/edit`);
  return null;
}

export async function deleteSection(sectionId: string, menuId: string): Promise<ActionResult> {
  const supabase = await createSupabaseServerClient();
  const { error } = await (supabase as any).from('menu_sections').delete().eq('id', sectionId);
  if (error) return { error: error.message };
  revalidatePath(`/owner/menus/${menuId}/edit`);
  return null;
}

export async function upsertItem(fd: FormData): Promise<ActionResult> {
  const menuId = String(fd.get('menuId') ?? '');
  const sectionId = String(fd.get('sectionId') ?? '');
  const itemId = fd.get('itemId') ? String(fd.get('itemId')) : null;
  const name = String(fd.get('name') ?? '').trim();
  const description = String(fd.get('description') ?? '').trim() || null;
  const priceRaw = parseFloat(String(fd.get('price') ?? '0'));
  const price_cents = Math.round(priceRaw * 100);
  const is_available = fd.get('is_available') === 'on';

  if (!name) return { error: 'Ürün adı boş olamaz' };
  if (isNaN(price_cents) || price_cents < 0) return { error: 'Geçersiz fiyat' };

  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return { error: 'Oturum bulunamadı' };

  const payload = { name, description, price_cents, currency: 'TRY', is_available, section_id: sectionId };

  let error: any;
  if (itemId) {
    ({ error } = await (supabase as any).from('menu_items').update(payload).eq('id', itemId));
  } else {
    const { count } = await (supabase as any).from('menu_items').select('id', { count: 'exact', head: true }).eq('section_id', sectionId) as { count: number | null };
    ({ error } = await (supabase as any).from('menu_items').insert({ ...payload, business_id: '', sort_order: (count ?? 0) }));
  }
  if (error) return { error: error.message };
  revalidatePath(`/owner/menus/${menuId}/edit`);
  return null;
}

export async function deleteItem(itemId: string, menuId: string): Promise<ActionResult> {
  const supabase = await createSupabaseServerClient();
  const { error } = await (supabase as any).from('menu_items').delete().eq('id', itemId);
  if (error) return { error: error.message };
  revalidatePath(`/owner/menus/${menuId}/edit`);
  return null;
}
