'use server';

import { revalidatePath } from 'next/cache';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { hasOwnerBusiness } from '@/src/lib/veri/owner/sahip-isletmeleri';
import { planLimitHataMesaji } from '@/src/lib/plan-limit-hata';

type ActionResult = { error: string } | null;

async function getOwnedMenuContext(menuId: string): Promise<
  | { ok: true; supabase: Awaited<ReturnType<typeof createSupabaseServerClient>>; businessId: string }
  | { ok: false; error: string }
> {
  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return { ok: false, error: 'Oturum bulunamadı' };

  const { data: menu, error } = await (supabase)
    .from('menus')
    .select('id,business_id')
    .eq('id', menuId)
    .maybeSingle() as { data: { id: string; business_id: string } | null; error: { message: string } | null };

  if (error) return { ok: false, error: error.message };
  if (!menu) return { ok: false, error: 'Menü bulunamadı' };

  const isOwner = await hasOwnerBusiness(supabase, user.id, menu.business_id, 'menu_write');
  if (!isOwner) return { ok: false, error: 'Bu menü için yetkiniz yok' };

  return { ok: true, supabase, businessId: menu.business_id };
}

function revalidateMenuEditor(menuId: string) {
  revalidatePath(`/sahip/menuler/${menuId}/duzenle`);
  revalidatePath(`/sahip/menuler/${menuId}/kategoriler`);
  revalidatePath(`/sahip/menuler/${menuId}`);
  revalidatePath('/sahip/menuler');
}

export async function updateMenuTitle(menuId: string, title: string): Promise<ActionResult> {
  if (!title.trim()) return { error: 'Başlık boş olamaz' };
  const context = await getOwnedMenuContext(menuId);
  if (!context.ok) return { error: context.error };
  const { error } = await (context.supabase).from('menus').update({ title: title.trim() }).eq('id', menuId);
  if (error) return { error: error.message };
  revalidateMenuEditor(menuId);
  return null;
}

export async function publishMenu(menuId: string, status: 'draft' | 'published' | 'archived'): Promise<ActionResult> {
  const context = await getOwnedMenuContext(menuId);
  if (!context.ok) return { error: context.error };
  const { error } = await (context.supabase).from('menus').update({ status }).eq('id', menuId);
  if (error) return { error: error.message };
  revalidateMenuEditor(menuId);
  return null;
}

export async function createSection(menuId: string, title: string, sortOrder: number): Promise<ActionResult> {
  if (!title.trim()) return { error: 'Bölüm adı boş olamaz' };
  const context = await getOwnedMenuContext(menuId);
  if (!context.ok) return { error: context.error };
  const { error } = await (context.supabase).from('menu_sections').insert({ menu_id: menuId, title: title.trim(), sort_order: sortOrder });
  if (error) return { error: error.message };
  revalidateMenuEditor(menuId);
  return null;
}

export async function updateSection(sectionId: string, menuId: string, title: string): Promise<ActionResult> {
  if (!title.trim()) return { error: 'Bölüm adı boş olamaz' };
  const context = await getOwnedMenuContext(menuId);
  if (!context.ok) return { error: context.error };
  const { error } = await (context.supabase)
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
  const { error } = await (context.supabase).from('menu_sections').delete().eq('id', sectionId).eq('menu_id', menuId);
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
  // Üst sınır yoktu — price_cents integer kolonu, taşma ham İngilizce
  // Postgres hatası üretiyordu. 1.000.000 TL/ürün, meşru kullanımın
  // çok üzerinde bir tavan.
  if (isNaN(price_cents) || price_cents < 0 || price_cents > 100_000_000) return { error: 'Geçersiz fiyat' };

  const context = await getOwnedMenuContext(menuId);
  if (!context.ok) return { error: context.error };

  const { data: section } = await (context.supabase)
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

  const caloriesMinRaw = fd.get('calories_min') ? Number(fd.get('calories_min')) : null;
  const caloriesMaxRaw = fd.get('calories_max') ? Number(fd.get('calories_max')) : null;
  const calorieSourceRaw = (fd.get('calorie_source') as string) || null;
  const portionSizeRaw = fd.get('portion_size') ? Number(fd.get('portion_size')) : null;
  const portionUnit = (fd.get('portion_unit') as string) || null;

  // calories_min/calories_max smallint kolonu (max 32767); sıra da hiç
  // doğrulanmıyordu.
  for (const v of [caloriesMinRaw, caloriesMaxRaw]) {
    if (v !== null && (isNaN(v) || v < 0 || v > 32000)) return { error: 'Geçersiz kalori değeri' };
  }
  if (caloriesMinRaw !== null && caloriesMaxRaw !== null && caloriesMinRaw > caloriesMaxRaw) {
    return { error: 'Minimum kalori maksimumdan büyük olamaz' };
  }

  const payload = {
    name,
    description,
    image_url: imageUrl,
    price_cents,
    currency: 'TRY',
    is_available,
    section_id: sectionId,
    calories_min: caloriesMinRaw,
    calories_max: caloriesMaxRaw ?? caloriesMinRaw,
    portion_size: portionSizeRaw,
    portion_unit: portionUnit,
    calorie_source: caloriesMinRaw !== null ? (calorieSourceRaw ?? 'owner') : 'unknown',
  };

  let resolvedItemId: string;

  if (itemId) {
    const { data: menuSections } = await (context.supabase)
      .from('menu_sections')
      .select('id')
      .eq('menu_id', menuId) as { data: Array<{ id: string }> | null };
    const menuSectionIds = (menuSections ?? []).map((s) => s.id);

    // .update() 0 satır etkilerse (itemId bu menüye ait değilse) hata
    // dönmüyordu, çağıran "başarılı" sanıyordu — .select() ile satırın
    // gerçekten güncellendiği doğrulanıyor.
    const { data: updated, error: updateErr } = await (context.supabase)
      .from('menu_items')
      .update(payload)
      .eq('id', itemId)
      .in('section_id', menuSectionIds)
      .select('id') as { data: { id: string }[] | null; error: { message: string } | null };
    if (updateErr) return { error: updateErr.message };
    if (!updated || updated.length === 0) return { error: 'Ürün bulunamadı' };
    resolvedItemId = itemId;
  } else {
    const { error: limitError } = await (context.supabase).rpc('_check_plan_limit_v1', {
      p_business_id: context.businessId,
      p_feature_key: 'menu_item_count',
    }) as { error: { code?: string; message?: string } | null };
    if (limitError) {
      return { error: planLimitHataMesaji(limitError, 'Ürün') };
    }

    const { count } = await (context.supabase)
      .from('menu_items')
      .select('id', { count: 'exact', head: true })
      .eq('section_id', sectionId) as { count: number | null };
    const { data: newItem, error: insertErr } = await (context.supabase)
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
  allergens: Array<{ code: string; status: 'confirmed' | 'possible'; evidence?: string }>,
): Promise<{ error: string } | null> {
  const context = await getOwnedMenuContext(menuId);
  if (!context.ok) return { error: context.error };

  const p_allergens = allergens.map(({ code, status, evidence }) => ({
    allergen: code,
    status,
    evidence: evidence ?? null,
    detected_by: evidence ? 'ai' : 'manual',
  }));

  const { data, error } = await (context.supabase).rpc('owner_upsert_menu_item_allergens_v1', {
    p_item_id: itemId,
    p_allergens,
  }) as { data: { ok: boolean; error?: string } | null; error: { message: string } | null };

  if (error) return { error: error.message };
  // RPC exception fırlatmıyor, {ok:false} dönebiliyor — kontrol edilmezse
  // panel "kaydedildi" derken alerjen listesi eski hâliyle kalabiliyordu.
  if (data?.ok === false) return { error: data.error ?? 'Alerjen bilgisi kaydedilemedi' };
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

  const { data, error } = await (context.supabase).rpc('owner_upsert_menu_item_ingredients_v1', {
    p_item_id: itemId,
    p_ingredients,
    p_diet: { is_vegan: null, is_vegetarian: null, is_gluten_free: null, is_dairy_free: null },
    p_detected_by: 'manual',
  }) as { data: { ok: boolean; error?: string } | null; error: { message: string } | null };

  if (error) return { error: error.message };
  if (data?.ok === false) return { error: data.error ?? 'Malzeme bilgisi kaydedilemedi' };
  revalidateMenuEditor(menuId);
  return null;
}

export async function deleteItem(itemId: string, menuId: string): Promise<ActionResult> {
  const context = await getOwnedMenuContext(menuId);
  if (!context.ok) return { error: context.error };

  const { data: sections } = await (context.supabase)
    .from('menu_sections')
    .select('id')
    .eq('menu_id', menuId) as { data: Array<{ id: string }> | null };
  const sectionIds = (sections ?? []).map((section) => section.id);
  if (sectionIds.length === 0) return { error: 'Bölüm bulunamadı' };

  const { data: item } = await (context.supabase)
    .from('menu_items')
    .select('id')
    .eq('id', itemId)
    .in('section_id', sectionIds)
    .maybeSingle() as { data: { id: string } | null };
  if (!item) return { error: 'Ürün bulunamadı' };

  // Kalıcı silme yerine çöp kutusuna taşıma — kalıcı silme yalnızca
  // /sahip/cop-kutusu üzerinden owner_permanently_delete_menu_item_v1 ile yapılır.
  const { data, error } = await (context.supabase).rpc('owner_soft_delete_menu_item_v1', { p_item_id: itemId }) as
    { data: { ok: boolean; code?: string } | null; error: { message: string } | null };
  if (error) return { error: error.message };
  if (data?.ok === false) return { error: data.code ?? 'Ürün silinemedi' };
  revalidateMenuEditor(menuId);
  return null;
}

export async function reorderItem(
  itemId: string,
  menuId: string,
  targetSectionId: string,
  newSortOrder: number,
): Promise<ActionResult> {
  if (!Number.isInteger(newSortOrder) || newSortOrder < 0) return { error: 'Geçersiz sıralama değeri' };

  const context = await getOwnedMenuContext(menuId);
  if (!context.ok) return { error: context.error };

  const { data: section } = await (context.supabase)
    .from('menu_sections')
    .select('id')
    .eq('id', targetSectionId)
    .eq('menu_id', menuId)
    .maybeSingle() as { data: { id: string } | null };
  if (!section) return { error: 'Bölüm bulunamadı' };

  // Tek item'ın sort_order'ını set etmek diğer item'ları kaydırmıyordu —
  // aynı sort_order'a sahip iki satır üretip sıralamayı kalıcı bozuyordu.
  // Artık atomik bir RPC bölüm içi kaydırmayı VE bölümler arası taşımayı
  // (gap kapatma + gap açma) tek transaction'da yapıyor.
  const { data, error } = await (context.supabase).rpc('owner_reorder_menu_item_v1', {
    p_item_id: itemId,
    p_target_section_id: targetSectionId,
    p_target_sort_order: newSortOrder,
  }) as { data: { ok: boolean; code?: string } | null; error: { message: string } | null };
  if (error) return { error: error.message };
  if (data?.ok === false) return { error: data.code ?? 'Sıralama güncellenemedi' };

  revalidateMenuEditor(menuId);
  return null;
}

export async function bulkSetAvailability(
  itemIds: string[],
  menuId: string,
  isAvailable: boolean,
): Promise<ActionResult> {
  if (itemIds.length === 0) return null;
  const context = await getOwnedMenuContext(menuId);
  if (!context.ok) return { error: context.error };

  const { data: sections } = await (context.supabase)
    .from('menu_sections')
    .select('id')
    .eq('menu_id', menuId) as { data: Array<{ id: string }> | null };
  const sectionIds = (sections ?? []).map((section) => section.id);
  if (sectionIds.length === 0) return { error: 'Bölüm bulunamadı' };

  const { error } = await (context.supabase)
    .from('menu_items')
    .update({ is_available: isAvailable })
    .in('id', itemIds)
    .in('section_id', sectionIds);
  if (error) return { error: error.message };

  revalidateMenuEditor(menuId);
  return null;
}

export async function bulkMoveSection(
  itemIds: string[],
  menuId: string,
  targetSectionId: string,
): Promise<ActionResult> {
  if (itemIds.length === 0) return null;
  const context = await getOwnedMenuContext(menuId);
  if (!context.ok) return { error: context.error };

  const { data: sections } = await (context.supabase)
    .from('menu_sections')
    .select('id')
    .eq('menu_id', menuId) as { data: Array<{ id: string }> | null };
  const sectionIds = (sections ?? []).map((section) => section.id);
  if (!sectionIds.includes(targetSectionId)) return { error: 'Hedef bölüm bu menüye ait değil' };

  const { error } = await (context.supabase)
    .from('menu_items')
    .update({ section_id: targetSectionId })
    .in('id', itemIds)
    .in('section_id', sectionIds);
  if (error) return { error: error.message };

  revalidateMenuEditor(menuId);
  return null;
}

export async function bulkDeleteItems(
  itemIds: string[],
  menuId: string,
): Promise<ActionResult> {
  if (itemIds.length === 0) return null;
  const context = await getOwnedMenuContext(menuId);
  if (!context.ok) return { error: context.error };

  const { data: sections } = await (context.supabase)
    .from('menu_sections')
    .select('id')
    .eq('menu_id', menuId) as { data: Array<{ id: string }> | null };
  const sectionIds = (sections ?? []).map((section) => section.id);
  if (sectionIds.length === 0) return { error: 'Bölüm bulunamadı' };

  const { data: items } = await (context.supabase)
    .from('menu_items')
    .select('id')
    .in('id', itemIds)
    .in('section_id', sectionIds) as { data: Array<{ id: string }> | null };

  // Kalıcı silme yerine çöp kutusuna taşıma — bkz. deleteItem.
  for (const item of items ?? []) {
    const { error } = await (context.supabase).rpc('owner_soft_delete_menu_item_v1', { p_item_id: item.id }) as
      { error: { message: string } | null };
    if (error) return { error: error.message };
  }

  revalidateMenuEditor(menuId);
  return null;
}

export async function duplicateItem(
  itemId: string,
  menuId: string,
): Promise<{ error: string } | { itemId: string }> {
  const context = await getOwnedMenuContext(menuId);
  if (!context.ok) return { error: context.error };

  const { data: sections } = await (context.supabase)
    .from('menu_sections')
    .select('id')
    .eq('menu_id', menuId) as { data: Array<{ id: string }> | null };
  const sectionIds = (sections ?? []).map((section) => section.id);
  if (sectionIds.length === 0) return { error: 'Bölüm bulunamadı' };

  type OrijinalUrunSatiri = {
    name: string; description: string | null; image_url: string | null; price_cents: number;
    currency: string; is_available: boolean; section_id: string; calories_min: number | null;
    calories_max: number | null; portion_size: number | null; portion_unit: string | null;
    calorie_source: string | null;
  };
  const { data: original, error: fetchErr } = await (context.supabase)
    .from('menu_items')
    .select('name, description, image_url, price_cents, currency, is_available, section_id, calories_min, calories_max, portion_size, portion_unit, calorie_source')
    .eq('id', itemId)
    .in('section_id', sectionIds)
    .maybeSingle() as { data: OrijinalUrunSatiri | null; error: { message: string } | null };
  if (fetchErr) return { error: fetchErr.message };
  if (!original) return { error: 'Ürün bulunamadı' };

  // upsertItem'daki gibi plan limiti kontrolü — önceden duplicateItem bu
  // kontrolü hiç çağırmadığı için free plandaki bir sahip kopyalama
  // üzerinden limitsiz ürün üretebiliyordu.
  const { error: limitError } = await (context.supabase).rpc('_check_plan_limit_v1', {
    p_business_id: context.businessId,
    p_feature_key: 'menu_item_count',
  }) as { error: { code?: string; message?: string } | null };
  if (limitError) {
    return { error: planLimitHataMesaji(limitError, 'Ürün') };
  }

  const { count } = await (context.supabase)
    .from('menu_items')
    .select('id', { count: 'exact', head: true })
    .eq('section_id', original.section_id) as { count: number | null };

  const { data: copy, error: insertErr } = await (context.supabase)
    .from('menu_items')
    .insert({
      ...original,
      name: `${original.name} (Kopya)`,
      business_id: context.businessId,
      sort_order: count ?? 0,
    })
    .select('id')
    .single() as { data: { id: string } | null; error: { message: string } | null };
  if (insertErr) return { error: insertErr.message };
  const copyId = copy?.id ?? '';

  // Alerjen/malzeme/çeviri satırları önceden hiç kopyalanmıyordu — kopya
  // üründe "alerjen bilgisi yok" gibi görünüp halka açık menüde yanlış
  // (veya eksik) bilgi yayınlanmasına yol açıyordu.
  const [{ data: allergens }, { data: ingredients }, { data: dietTags }, { data: translations }] = await Promise.all([
    (context.supabase).from('menu_item_allergens').select('allergen, status, evidence').eq('item_id', itemId) as unknown as Promise<{ data: Array<{ allergen: string; status: string; evidence: string | null }> | null }>,
    (context.supabase).from('menu_item_ingredients').select('name, confidence, category').eq('item_id', itemId).order('sort_order') as unknown as Promise<{ data: Array<{ name: string; confidence: string; category: string }> | null }>,
    (context.supabase).from('menu_item_diet_tags').select('is_vegan, is_vegetarian, is_gluten_free, is_dairy_free').eq('item_id', itemId).maybeSingle() as unknown as Promise<{ data: { is_vegan: boolean | null; is_vegetarian: boolean | null; is_gluten_free: boolean | null; is_dairy_free: boolean | null } | null }>,
    (context.supabase).from('menu_translations').select('locale, name, description').eq('entity_type', 'item').eq('entity_id', itemId) as unknown as Promise<{ data: Array<{ locale: string; name: string; description: string | null }> | null }>,
  ]);

  if (copyId && allergens?.length) {
    await (context.supabase).rpc('owner_upsert_menu_item_allergens_v1', {
      p_item_id: copyId,
      p_allergens: allergens.map((a) => ({ allergen: a.allergen, status: a.status, evidence: a.evidence ?? undefined })),
    });
  }
  if (copyId && (ingredients?.length || dietTags)) {
    await (context.supabase).rpc('owner_upsert_menu_item_ingredients_v1', {
      p_item_id: copyId,
      p_ingredients: (ingredients ?? []).map((i) => ({ name: i.name, confidence: i.confidence, category: i.category })),
      p_diet: dietTags ?? { is_vegan: null, is_vegetarian: null, is_gluten_free: null, is_dairy_free: null },
      p_detected_by: 'manual',
    });
  }
  if (copyId && translations?.length) {
    await (context.supabase).from('menu_translations').insert(
      translations.map((t) => ({ entity_type: 'item', entity_id: copyId, locale: t.locale, name: t.name, description: t.description })),
    );
  }

  revalidateMenuEditor(menuId);
  return { itemId: copyId };
}
