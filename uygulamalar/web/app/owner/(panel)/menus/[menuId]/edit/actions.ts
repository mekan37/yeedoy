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

export async function upsertItem(fd: FormData): Promise<{ itemId: string } | { error: string }> {
  const menuId = String(fd.get('menuId') ?? '');
  const sectionId = String(fd.get('sectionId') ?? '');
  const itemId = fd.get('itemId') ? String(fd.get('itemId')) : null;
  const name = String(fd.get('name') ?? '').trim();
  const description = String(fd.get('description') ?? '').trim() || null;
  const priceRaw = parseFloat(String(fd.get('price') ?? '0'));
  const price_cents = Math.round(priceRaw * 100);
  const is_available = fd.get('is_available') === 'on';
  const image_url = String(fd.get('image_url') ?? '').trim() || null;

  // Build tags from dietary flags + custom tags
  const dietaryTags: string[] = [];
  if (fd.get('diet_vegan') === 'on') dietaryTags.push('vegan');
  if (fd.get('diet_vegetarian') === 'on') dietaryTags.push('vegetarian');
  if (fd.get('diet_glutenfree') === 'on') dietaryTags.push('glutensiz');
  if (fd.get('diet_lactosefree') === 'on') dietaryTags.push('laktossuz');
  if (fd.get('diet_halal') === 'on') dietaryTags.push('halal');
  const customTagInput = String(fd.get('custom_tags') ?? '').trim();
  const customTags = customTagInput ? customTagInput.split(',').map((t) => t.trim()).filter(Boolean) : [];
  const allTags = [...new Set([...dietaryTags, ...customTags])];
  const tags = allTags.length > 0 ? allTags : null;

  const calories_min = fd.get('calories_min') ? parseInt(String(fd.get('calories_min'))) || null : null;
  const calories_max = fd.get('calories_max') ? parseInt(String(fd.get('calories_max'))) || null : null;
  const portion_size = String(fd.get('portion_size') ?? '').trim() || null;
  const portion_unit = String(fd.get('portion_unit') ?? '').trim() || null;

  if (!name) return { error: 'Ürün adı boş olamaz' };
  if (isNaN(price_cents) || price_cents < 0) return { error: 'Geçersiz fiyat' };

  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return { error: 'Oturum bulunamadı' };

  const payload = {
    name, description, price_cents, currency: 'TRY', is_available,
    section_id: sectionId, image_url, tags,
    calories_min, calories_max, portion_size, portion_unit,
  };

  if (itemId) {
    const { error } = await (supabase as any).from('menu_items').update(payload).eq('id', itemId);
    if (error) return { error: error.message };
    revalidatePath(`/owner/menus/${menuId}/edit`);
    return { itemId };
  }

  // Get business_id from the menu (required column on menu_items)
  const { data: menuRow } = await (supabase as any)
    .from('menus').select('business_id').eq('id', menuId).single() as { data: { business_id: string } | null };
  if (!menuRow) return { error: 'Menü bulunamadı' };

  const { count } = await (supabase as any)
    .from('menu_items').select('id', { count: 'exact', head: true }).eq('section_id', sectionId) as { count: number | null };

  const { data: inserted, error } = await (supabase as any)
    .from('menu_items')
    .insert({ ...payload, business_id: menuRow.business_id, sort_order: count ?? 0 })
    .select('id')
    .single() as { data: { id: string } | null; error: any };

  if (error) return { error: error.message };
  if (!inserted) return { error: 'Ürün eklenemedi' };
  revalidatePath(`/owner/menus/${menuId}/edit`);
  return { itemId: inserted.id };
}

export async function upsertItemAllergens(
  itemId: string,
  allergens: { allergen: string; risk_level: 'contains' | 'may_contain' }[],
): Promise<ActionResult> {
  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return { error: 'Oturum bulunamadı' };
  const { error } = await (supabase as any).rpc('owner_upsert_menu_item_allergens_v1', {
    p_item_id: itemId,
    p_allergens: JSON.stringify(allergens),
  });
  if (error) return { error: error.message };
  return null;
}

export async function getItemAllergens(
  itemId: string,
): Promise<{ allergen: string; risk_level: 'contains' | 'may_contain' }[]> {
  const supabase = await createSupabaseServerClient();
  const { data } = await (supabase as any)
    .from('menu_item_allergens')
    .select('allergen, risk_level')
    .eq('item_id', itemId) as { data: { allergen: string; risk_level: 'contains' | 'may_contain' }[] | null };
  return data ?? [];
}

export async function deleteItem(itemId: string, menuId: string): Promise<ActionResult> {
  const supabase = await createSupabaseServerClient();
  const { error } = await (supabase as any).from('menu_items').delete().eq('id', itemId);
  if (error) return { error: error.message };
  revalidatePath(`/owner/menus/${menuId}/edit`);
  return null;
}
