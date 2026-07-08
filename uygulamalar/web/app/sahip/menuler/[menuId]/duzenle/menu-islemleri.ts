'use server';

import { revalidatePath } from 'next/cache';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { hasOwnerBusiness } from '@/src/lib/veri/owner/sahip-isletmeleri';

type ActionResult = { error: string } | null;

async function getOwnedMenuContext(menuId: string): Promise<
  | { ok: true; supabase: Awaited<ReturnType<typeof createSupabaseServerClient>>; businessId: string }
  | { ok: false; error: string }
> {
  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return { ok: false, error: 'Oturum bulunamadı' };

  const { data: menu, error } = await (supabase as any)
    .from('menus')
    .select('id,business_id')
    .eq('id', menuId)
    .maybeSingle() as { data: { id: string; business_id: string } | null; error: { message: string } | null };

  if (error) return { ok: false, error: error.message };
  if (!menu) return { ok: false, error: 'Menü bulunamadı' };

  const isOwner = await hasOwnerBusiness(supabase as any, user.id, menu.business_id);
  if (!isOwner) return { ok: false, error: 'Bu menü için yetkiniz yok' };

  return { ok: true, supabase, businessId: menu.business_id };
}

function revalidateMenuEditor(menuId: string) {
  revalidatePath(`/sahip/menuler/${menuId}/duzenle`);
  revalidatePath(`/sahip/menuler/${menuId}`);
  revalidatePath('/sahip/menuler');
}

export async function updateMenuTitle(menuId: string, title: string): Promise<ActionResult> {
  if (!title.trim()) return { error: 'Başlık boş olamaz' };
  const context = await getOwnedMenuContext(menuId);
  if (!context.ok) return { error: context.error };
  const { error } = await (context.supabase as any).from('menus').update({ title: title.trim() }).eq('id', menuId);
  if (error) return { error: error.message };
  revalidateMenuEditor(menuId);
  return null;
}

export async function publishMenu(menuId: string, status: 'draft' | 'published' | 'archived'): Promise<ActionResult> {
  const context = await getOwnedMenuContext(menuId);
  if (!context.ok) return { error: context.error };
  const { error } = await (context.supabase as any).from('menus').update({ status }).eq('id', menuId);
  if (error) return { error: error.message };
  revalidateMenuEditor(menuId);
  return null;
}

export async function createSection(menuId: string, title: string, sortOrder: number): Promise<ActionResult> {
  if (!title.trim()) return { error: 'Bölüm adı boş olamaz' };
  const context = await getOwnedMenuContext(menuId);
  if (!context.ok) return { error: context.error };
  const { error } = await (context.supabase as any).from('menu_sections').insert({ menu_id: menuId, title: title.trim(), sort_order: sortOrder });
  if (error) return { error: error.message };
  revalidateMenuEditor(menuId);
  return null;
}

export async function updateSection(sectionId: string, menuId: string, title: string): Promise<ActionResult> {
  if (!title.trim()) return { error: 'Bölüm adı boş olamaz' };
  const context = await getOwnedMenuContext(menuId);
  if (!context.ok) return { error: context.error };
  const { error } = await (context.supabase as any)
    .from('menu_sections')
    .update({ title: title.trim() })
    .eq('id', sectionId)
    .eq('menu_id', menuId);
  if (error) return { error: error.message };
  revalidateMenuEditor(menuId);
  return null;
}

export async function deleteSection(sectionId: string, menuId: string): Promise<ActionResult> {
  const context = await getOwnedMenuContext(menuId);
  if (!context.ok) return { error: context.error };
  const { error } = await (context.supabase as any).from('menu_sections').delete().eq('id', sectionId).eq('menu_id', menuId);
  if (error) return { error: error.message };
  revalidateMenuEditor(menuId);
  return null;
}

export async function upsertItem(fd: FormData): Promise<{ error: string } | { itemId: string }> {
  const menuId = String(fd.get('menuId') ?? '');
  const sectionId = String(fd.get('sectionId') ?? '');
  const itemId = fd.get('itemId') ? String(fd.get('itemId')) : null;
  const name = String(fd.get('name') ?? '').trim();
  const description = String(fd.get('description') ?? '').trim() || null;
  const imageUrl = String(fd.get('imageUrl') ?? '').trim() || null;
  const priceRaw = parseFloat(String(fd.get('price') ?? '0'));
  const price_cents = Math.round(priceRaw * 100);
  const is_available = fd.get('is_available') === 'on';

  if (!name) return { error: 'Ürün adı boş olamaz' };
  if (isNaN(price_cents) || price_cents < 0) return { error: 'Geçersiz fiyat' };

  const context = await getOwnedMenuContext(menuId);
  if (!context.ok) return { error: context.error };

  const { data: section } = await (context.supabase as any)
    .from('menu_sections')
    .select('id')
    .eq('id', sectionId)
    .eq('menu_id', menuId)
    .maybeSingle() as { data: { id: string } | null };

  if (!section) return { error: 'Bölüm bulunamadı' };

  if (imageUrl) {
    try {
      const parsedUrl = new URL(imageUrl);
      if (!['http:', 'https:'].includes(parsedUrl.protocol)) {
        return { error: 'Görsel bağlantısı http veya https olmalı' };
      }
    } catch {
      return { error: 'Geçersiz görsel bağlantısı' };
    }
  }

  const caloriesRaw = fd.get('calories') ? Number(fd.get('calories')) : null;
  const portionSizeRaw = fd.get('portion_size') ? Number(fd.get('portion_size')) : null;
  const portionUnit = (fd.get('portion_unit') as string) || null;

  const payload = {
    name,
    description,
    image_url: imageUrl,
    price_cents,
    currency: 'TRY',
    is_available,
    section_id: sectionId,
    calories_min: caloriesRaw,
    calories_max: caloriesRaw,
    portion_size: portionSizeRaw,
    portion_unit: portionUnit,
    calorie_source: caloriesRaw !== null ? 'owner' : 'unknown',
  };

  let resolvedItemId: string;

  if (itemId) {
    const { error: updateErr } = await (context.supabase as any)
      .from('menu_items')
      .update(payload)
      .eq('id', itemId)
      .eq('section_id', sectionId) as { error: { message: string } | null };
    if (updateErr) return { error: updateErr.message };
    resolvedItemId = itemId;
  } else {
    const { count } = await (context.supabase as any)
      .from('menu_items')
      .select('id', { count: 'exact', head: true })
      .eq('section_id', sectionId) as { count: number | null };
    const { data: newItem, error: insertErr } = await (context.supabase as any)
      .from('menu_items')
      .insert({ ...payload, business_id: context.businessId, sort_order: (count ?? 0) })
      .select('id')
      .single() as { data: { id: string } | null; error: { message: string } | null };
    if (insertErr) return { error: insertErr.message };
    resolvedItemId = newItem?.id ?? '';
  }

  revalidateMenuEditor(menuId);
  return { itemId: resolvedItemId };
}

export async function upsertItemAllergens(
  itemId: string,
  menuId: string,
  allergenCodes: string[],
): Promise<{ error: string } | null> {
  const context = await getOwnedMenuContext(menuId);
  if (!context.ok) return { error: context.error };

  const p_allergens = allergenCodes.map((code) => ({
    allergen: code,
    risk_level: 'contains',
    detected_by: 'manual',
  }));

  const { error } = await (context.supabase as any).rpc('owner_upsert_menu_item_allergens_v1', {
    p_item_id: itemId,
    p_allergens,
  }) as { error: { message: string } | null };

  if (error) return { error: error.message };
  revalidateMenuEditor(menuId);
  return null;
}

export async function upsertItemIngredients(
  itemId: string,
  menuId: string,
  ingredientNames: string[],
): Promise<{ error: string } | null> {
  const context = await getOwnedMenuContext(menuId);
  if (!context.ok) return { error: context.error };

  const p_ingredients = ingredientNames.map((name, i) => ({
    name,
    confidence: 'certain',
    category: 'other',
    sort_order: i,
  }));

  const { error } = await (context.supabase as any).rpc('owner_upsert_menu_item_ingredients_v1', {
    p_item_id: itemId,
    p_ingredients,
    p_diet: { is_vegan: null, is_vegetarian: null, is_gluten_free: null, is_dairy_free: null },
    p_detected_by: 'manual',
  }) as { error: { message: string } | null };

  if (error) return { error: error.message };
  revalidateMenuEditor(menuId);
  return null;
}

export async function deleteItem(itemId: string, menuId: string): Promise<ActionResult> {
  const context = await getOwnedMenuContext(menuId);
  if (!context.ok) return { error: context.error };

  const { data: sections } = await (context.supabase as any)
    .from('menu_sections')
    .select('id')
    .eq('menu_id', menuId) as { data: Array<{ id: string }> | null };
  const sectionIds = (sections ?? []).map((section) => section.id);
  if (sectionIds.length === 0) return { error: 'Bölüm bulunamadı' };

  const { error } = await (context.supabase as any).from('menu_items').delete().eq('id', itemId).in('section_id', sectionIds);
  if (error) return { error: error.message };
  revalidateMenuEditor(menuId);
  return null;
}
