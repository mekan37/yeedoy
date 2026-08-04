'use server';

import { revalidatePath } from 'next/cache';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { getOwnerBusinessIds } from '@/src/lib/veri/owner/sahip-isletmeleri';
import { logger } from '@/src/lib/kayitci';
import {
  DESTEKLENEN_DILLER,
  type DestekDil,
  type CeviriSatiri,
} from './ceviri-sabitleri';

export type MenuCevirileriSonuc =
  | { success: true; satirlar: CeviriSatiri[]; toplamAdet: number }
  | { success: false; hata: string };

export async function menuCevirileriniGetir(
  businessId: string,
  menuId?: string,
): Promise<MenuCevirileriSonuc> {
  const supabase = await createSupabaseServerClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) return { success: false, hata: 'Oturum açmanız gerekiyor.' };

  const ownerBusinessIds = await getOwnerBusinessIds(supabase, user.id);
  if (!ownerBusinessIds.includes(businessId)) {
    return { success: false, hata: 'Bu işletmeye erişim yetkiniz yok.' };
  }

  // İlk dil (en) için temel satırları çek — item listesini oluşturur
  const baseRows = await fetchRowsForLocale(
    supabase,
    businessId,
    menuId ?? null,
    DESTEKLENEN_DILLER[0],
  );

  if (!baseRows.success) {
    return { success: false, hata: baseRows.hata };
  }

  // Satır haritası: itemId → CeviriSatiri
  const satirHaritasi = new Map<string, CeviriSatiri>();

  for (const row of baseRows.items) {
    satirHaritasi.set(row.item_id as string, {
      itemId: row.item_id as string,
      itemNameTr: (row.item_name_tr as string) ?? '',
      itemDescTr: (row.item_desc_tr as string | null) ?? null,
      sectionName: (row.section_name as string) ?? '',
      menuId: (row.menu_id as string) ?? '',
      menuTitle: (row.menu_title as string) ?? '',
      translations: {
        [DESTEKLENEN_DILLER[0]]: {
          name: (row.trans_name as string | null) ?? null,
          description: (row.trans_desc as string | null) ?? null,
        },
      },
    });
  }

  // Diğer diller için de çek ve haritayı zenginleştir
  for (let i = 1; i < DESTEKLENEN_DILLER.length; i++) {
    const locale = DESTEKLENEN_DILLER[i];
    const extraRows = await fetchRowsForLocale(
      supabase,
      businessId,
      menuId ?? null,
      locale,
    );
    if (extraRows.success) {
      for (const row of extraRows.items) {
        const existing = satirHaritasi.get(row.item_id as string);
        if (existing) {
          existing.translations[locale] = {
            name: (row.trans_name as string | null) ?? null,
            description: (row.trans_desc as string | null) ?? null,
          };
        }
      }
    }
  }

  const satirlar = Array.from(satirHaritasi.values());
  return { success: true, satirlar, toplamAdet: baseRows.total };
}

async function fetchRowsForLocale(
  supabase: Awaited<ReturnType<typeof createSupabaseServerClient>>,
  businessId: string,
  menuId: string | null,
  locale: DestekDil,
): Promise<
  | { success: true; items: Record<string, unknown>[]; total: number }
  | { success: false; hata: string }
> {
  const { data, error } = await (supabase as any).rpc(
    'list_menu_item_translations_v1',
    {
      p_business_id: businessId,
      p_menu_id: menuId ?? null,
      p_locale: locale,
      p_limit: 200,
      p_offset: 0,
    },
  );

  if (error) {
    logger.warn('list_menu_item_translations_v1 failed', { businessId, locale, error });
    return { success: false, hata: error.message };
  }

  const payload = data as {
    total: number;
    items: Record<string, unknown>[];
  };

  return {
    success: true,
    items: payload?.items ?? [],
    total: payload?.total ?? 0,
  };
}

// ── Upsert action ──────────────────────────────────────────────────────────────

export type CeviriKaydetSonuc =
  | { success: true }
  | { success: false; hata: string };

export async function menuCevirisiniKaydet(
  businessId: string,
  itemId: string,
  locale: DestekDil,
  name: string,
  description: string,
): Promise<CeviriKaydetSonuc> {
  const trimmedName = name.trim();
  if (!trimmedName) return { success: false, hata: 'Çeviri adı boş olamaz.' };

  const supabase = await createSupabaseServerClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) return { success: false, hata: 'Oturum açmanız gerekiyor.' };

  const ownerBusinessIds = await getOwnerBusinessIds(supabase, user.id);
  if (!ownerBusinessIds.includes(businessId)) {
    return { success: false, hata: 'Bu işletmeye erişim yetkiniz yok.' };
  }

  const { error } = await (supabase as any).rpc('upsert_menu_item_translation_v1', {
    p_item_id: itemId,
    p_locale: locale,
    p_name: trimmedName,
    p_description: description.trim() || null,
  });

  if (error) {
    logger.warn('upsert_menu_item_translation_v1 failed', { itemId, locale, error });
    if (error.message.includes('plan_limit_exceeded')) {
      return { success: false, hata: 'Bu dil planınızda yok. Daha fazla dil eklemek için planınızı yükseltin.' };
    }
    return { success: false, hata: error.message };
  }

  revalidatePath('/sahip/menu/ceviriler');

  return { success: true };
}
