import { unstable_cache } from 'next/cache';
import { createSupabasePublicClient } from '@/src/lib/taban/acik';
import { logger } from '@/src/lib/kayitci';
import type { Database } from '@/src/lib/taban/veri-tanimlari';
import { getResolvedBusinessPresentationSettings } from '@/src/lib/veri/sunum-ayarlari-veri';
import type { ResolvedPresentationRecord } from '@/src/lib/sunum-ayarlari';

type Business = Database['public']['Tables']['businesses']['Row'];
type BusinessMedia = Database['public']['Tables']['business_media']['Row'];
// BusinessHours (legacy wide-format table) type retained only for internal reference.
// New code uses BusinessHoursInfo from get_business_hours_v1 RPC.
type Menu = Database['public']['Tables']['menus']['Row'];
type MenuCategory = Database['public']['Tables']['menu_categories']['Row'];
type MenuSection = Database['public']['Tables']['menu_sections']['Row'];
type MenuItem = Database['public']['Tables']['menu_items']['Row'];
type MenuTranslation = Database['public']['Tables']['menu_translations']['Row'];
type MenuItemDietary = Database['public']['Functions']['get_menu_items_v1']['Returns'][number];
type MenuItemVariant = Database['public']['Functions']['get_menu_item_variants_v1']['Returns'][number];
type MenuItemPhoto = Database['public']['Functions']['get_menu_item_photos_v1']['Returns'][number];

const businessIdentifierPattern = /^[0-9a-fA-F-]{36}$/;
const businessSlugPattern = /^[a-z0-9]+(?:-[a-z0-9]+)*$/;
const businessSelect =
  'id,name,slug,public_slug,category,description,phone,address,city,district,lat,lng,is_active,created_at,logo_url,cover_url,reservation_url,order_yemeksepeti_url,order_trendyolgo_url,order_getir_url,neighborhood,is_verified';

export type BusinessMediaBundle = {
  logoUrl: string | null;
  coverUrl: string | null;
  gallery: BusinessMedia[];
};

export type MenuItemRecord = MenuItem & {
  tagList: string[];
  allergens: string[];   // list of AllergenType codes ('gluten', 'milk', ...)
  ingredients: string[]; // ingredient names in sort_order
  dietary: {
    calories: number | null;
    isVegan: boolean;
    isVegetarian: boolean;
    isGlutenFree: boolean;
    isLactoseFree: boolean;
    isHalal: boolean;
  };
};

export type BusinessSocialLinks = {
  website: string | null;
  instagram: string | null;
  whatsapp: string | null;
  facebook: string | null;
  tiktok: string | null;
};

export type PublicMenuData = {
  business: Business;
  businessHours: BusinessHoursInfo;
  socialLinks: BusinessSocialLinks | null;
  media: BusinessMediaBundle;
  presentation: ResolvedPresentationRecord;
  menu: Menu;
  sections: MenuSection[];
  categories: MenuCategory[];
  items: MenuItemRecord[];
  translations: MenuTranslation[];
};

function parseTagList(value: Database['public']['Tables']['menu_items']['Row']['tags']) {
  if (!Array.isArray(value)) return [];
  return value
    .map((entry) => String(entry ?? '').trim())
    .filter(Boolean);
}

function normalizeMenuItems(
  baseItems: MenuItem[],
  dietaryRows: MenuItemDietary[],
  allergenRows: Array<{ item_id: string; allergen: string }>,
  ingredientRows: Array<{ item_id: string; name: string }>,
) {
  const dietaryById = new Map(dietaryRows.map((row) => [row.id, row]));
  const allergensByItem = new Map<string, string[]>();
  for (const row of allergenRows) {
    const list = allergensByItem.get(row.item_id) ?? [];
    list.push(row.allergen);
    allergensByItem.set(row.item_id, list);
  }
  const ingredientsByItem = new Map<string, string[]>();
  for (const row of ingredientRows) {
    const list = ingredientsByItem.get(row.item_id) ?? [];
    list.push(row.name);
    ingredientsByItem.set(row.item_id, list);
  }

  return baseItems.map((item) => {
    const dietary = dietaryById.get(item.id);
    return {
      ...item,
      tagList: parseTagList(item.tags),
      allergens: allergensByItem.get(item.id) ?? [],
      ingredients: ingredientsByItem.get(item.id) ?? [],
      dietary: {
        calories: dietary?.calories ?? null,
        isVegan: Boolean(dietary?.is_vegan),
        isVegetarian: Boolean(dietary?.is_vegetarian),
        isGlutenFree: Boolean(dietary?.is_gluten_free),
        isLactoseFree: Boolean(dietary?.is_lactose_free),
        isHalal: Boolean(dietary?.is_halal),
      },
    };
  });
}

const getBusinessByIdCached = unstable_cache(
  async (businessId: string) => {
    const supabase = createSupabasePublicClient();
    const { data, error } = await supabase
      .from('businesses')
      .select(businessSelect)
      .eq('id', businessId)
      .eq('is_active', true)
      .maybeSingle();

    if (error) {
      logger.error('Failed to fetch business', { businessId, error });
      return null;
    }

    return (data ?? null) as Business | null;
  },
  ['public-business-by-id'],
  { revalidate: 300 },
);

const getBusinessBySlugCached = unstable_cache(
  async (slugOrPublicSlug: string) => {
    const supabase = createSupabasePublicClient();
    const { data, error } = await supabase
      .from('businesses')
      .select(businessSelect)
      .or(`public_slug.eq.${slugOrPublicSlug},slug.eq.${slugOrPublicSlug}`)
      .eq('is_active', true)
      .maybeSingle();

    if (error) {
      logger.error('Failed to fetch business by slug', { slugOrPublicSlug, error });
      return null;
    }

    return (data ?? null) as Business | null;
  },
  ['public-business-by-slug'],
  { revalidate: 300 },
);

function normalizeBusinessSlugIdentifier(identifier: string) {
  const normalized = identifier.trim().toLowerCase();
  if (!normalized || !businessSlugPattern.test(normalized)) return null;
  return normalized;
}

export async function getBusinessBySlugOrId(identifier: string) {
  const normalized = identifier.trim();
  if (!normalized) return null;
  if (businessIdentifierPattern.test(normalized)) {
    return getBusinessByIdCached(normalized);
  }

  const slug = normalizeBusinessSlugIdentifier(normalized);
  if (!slug) return null;
  return getBusinessBySlugCached(slug);
}

/**
 * @deprecated Reads legacy business_hours (wide-format) table which is no longer written
 * by the owner panel. Use getBusinessHoursInfo() which calls get_business_hours_v1 RPC
 * and reads the canonical business_weekly_hours table instead.
 * Remove after 2026-09-01.
 */
// getBusinessHours / getBusinessHoursCached removed — all callers migrated to getBusinessHoursInfo.

export type BusinessHoursInfo = {
  isOpenNow: boolean | null;
  weekly: Array<{
    day_of_week: number;
    open_time: string;
    close_time: string;
    is_closed: boolean;
  }>;
};

const getBusinessHoursInfoCached = unstable_cache(
  async (businessId: string): Promise<BusinessHoursInfo> => {
    const supabase = createSupabasePublicClient();
    try {
      const { data, error } = await (supabase as unknown as {
        rpc: (
          fn: 'get_business_hours_v1',
          args: { p_business_id: string },
        ) => Promise<{
          data: { is_open_now: boolean | null; weekly: BusinessHoursInfo['weekly'] } | null;
          error: unknown;
        }>;
      }).rpc('get_business_hours_v1', { p_business_id: businessId });
      if (error || !data) return { isOpenNow: null, weekly: [] };
      return { isOpenNow: data.is_open_now ?? null, weekly: data.weekly ?? [] };
    } catch {
      return { isOpenNow: null, weekly: [] };
    }
  },
  ['public-business-hours-info'],
  { revalidate: 120 },
);

export async function getBusinessHoursInfo(businessId: string): Promise<BusinessHoursInfo> {
  return getBusinessHoursInfoCached(businessId);
}

/** @deprecated Use getBusinessHoursInfo instead */
export async function getBusinessIsOpenNow(businessId: string): Promise<boolean | null> {
  return (await getBusinessHoursInfoCached(businessId)).isOpenNow;
}

const getBusinessMediaCached = unstable_cache(
  async (businessId: string, logoUrl: string | null, coverUrl: string | null) => {
    const supabase = createSupabasePublicClient();
    const { data, error } = await supabase
      .from('business_media')
      .select('*')
      .eq('business_id', businessId)
      .eq('is_hidden', false)
      .order('created_at', { ascending: false });

    if (error) {
      logger.warn('Failed to fetch business media', { businessId, error });
      return { logoUrl, coverUrl, gallery: [] } satisfies BusinessMediaBundle;
    }

    const gallery: BusinessMedia[] = (data ?? []) as BusinessMedia[];
    const logo = gallery.find((entry) => entry.kind === 'logo');
    const cover = gallery.find((entry) => entry.kind === 'cover' || entry.kind === 'hero');

    return {
      logoUrl: logo?.url ?? logoUrl,
      coverUrl: cover?.url_large ?? cover?.url ?? coverUrl,
      gallery,
    } satisfies BusinessMediaBundle;
  },
  ['public-business-media'],
  { revalidate: 300 },
);

export async function getBusinessMedia(business: Pick<Business, 'id' | 'logo_url' | 'cover_url'>) {
  return getBusinessMediaCached(business.id, business.logo_url, business.cover_url);
}

const getMenuForBusinessCached = unstable_cache(
  async (businessId: string) => {
    const supabase = createSupabasePublicClient();
    const { data, error } = await supabase
      .from('menus')
      .select('*')
      .eq('business_id', businessId)
      .eq('status', 'published')
      .order('version', { ascending: false })
      .order('updated_at', { ascending: false })
      .limit(1)
      .maybeSingle();

    if (error) {
      logger.error('Failed to fetch published menu', { businessId, error });
      return null;
    }

    return (data ?? null) as Menu | null;
  },
  ['public-business-menu'],
  { revalidate: 120 },
);

export async function getMenuForBusiness(businessId: string) {
  return getMenuForBusinessCached(businessId);
}

const getMenuSectionsCached = unstable_cache(
  async (menuId: string) => {
    const supabase = createSupabasePublicClient();
    const { data, error } = await supabase
      .from('menu_sections')
      .select('*')
      .eq('menu_id', menuId)
      .order('sort_order');

    if (error) {
      logger.error('Failed to fetch menu sections', { menuId, error });
      return [] as MenuSection[];
    }

    return (data ?? []) as MenuSection[];
  },
  ['public-menu-sections'],
  { revalidate: 120 },
);

export async function getMenuSections(menuId: string) {
  return getMenuSectionsCached(menuId);
}

const getMenuCategoriesCached = unstable_cache(
  async (businessId: string, menuId: string) => {
    const supabase = createSupabasePublicClient();
    const scoped = await supabase
      .from('menu_categories')
      .select('*')
      .eq('business_id', businessId)
      .eq('menu_id', menuId)
      .eq('is_active', true)
      .order('sort_order');

    if (!scoped.error && (scoped.data?.length ?? 0) > 0) {
      return (scoped.data ?? []) as MenuCategory[];
    }

    const fallback = await supabase
      .from('menu_categories')
      .select('*')
      .eq('business_id', businessId)
      .eq('is_active', true)
      .order('sort_order');

    if (fallback.error) {
      logger.warn('Failed to fetch menu categories', { businessId, menuId, error: fallback.error });
      return [] as MenuCategory[];
    }

    return (fallback.data ?? []) as MenuCategory[];
  },
  ['public-menu-categories'],
  { revalidate: 120 },
);

export async function getMenuCategories(businessId: string, menuId: string) {
  return getMenuCategoriesCached(businessId, menuId);
}

const getMenuItemsCached = unstable_cache(
  async (businessId: string, menuId: string) => {
    const supabase = createSupabasePublicClient();
    const sections = await getMenuSections(menuId);
    const sectionIds = sections.map((section) => section.id);

    let query = supabase
      .from('menu_items')
      .select('*')
      .eq('business_id', businessId)
      .order('sort_order') as unknown as PromiseLike<{
        data: MenuItem[] | null;
        error: unknown;
      }> & {
        in: (column: string, values: string[]) => PromiseLike<{
          data: MenuItem[] | null;
          error: unknown;
        }>;
      };

    if (sectionIds.length > 0) {
      query = query.in('section_id', sectionIds) as typeof query;
    }

    const itemsResponse = await query;

    if (itemsResponse.error) {
      logger.error('Failed to fetch menu items', { businessId, menuId, error: itemsResponse.error });
      return [] as MenuItemRecord[];
    }

    const dietaryResponse = await (supabase as unknown as {
      rpc: (
        fn: 'get_menu_items_v1',
        args: Database['public']['Functions']['get_menu_items_v1']['Args'],
      ) => Promise<{ data: MenuItemDietary[] | null; error: unknown }>;
    }).rpc('get_menu_items_v1', { p_menu_id: menuId });
    const dietaryRows: MenuItemDietary[] = dietaryResponse.error ? [] : dietaryResponse.data ?? [];

    if (dietaryResponse.error) {
      logger.warn('Failed to fetch dietary menu item data', { menuId, error: dietaryResponse.error });
    }

    // Batch-fetch allergens for all items in this menu
    const itemIds = (itemsResponse.data ?? []).map((i: MenuItem) => i.id);
    let allergenRows: Array<{ item_id: string; allergen: string }> = [];
    if (itemIds.length > 0) {
      const allergenResponse = await supabase
        .from('menu_item_allergens')
        .select('item_id,allergen')
        .in('item_id', itemIds);
      if (!allergenResponse.error) {
        allergenRows = (allergenResponse.data ?? []) as Array<{ item_id: string; allergen: string }>;
      }
    }

    // Batch-fetch ingredients for all items in this menu
    let ingredientRows: Array<{ item_id: string; name: string }> = [];
    if (itemIds.length > 0) {
      const ingredientResponse = await supabase
        .from('menu_item_ingredients')
        .select('item_id,name')
        .in('item_id', itemIds)
        .order('sort_order');
      if (!ingredientResponse.error) {
        ingredientRows = (ingredientResponse.data ?? []) as Array<{ item_id: string; name: string }>;
      }
    }

    return normalizeMenuItems((itemsResponse.data ?? []) as MenuItem[], dietaryRows, allergenRows, ingredientRows);
  },
  ['public-menu-items'],
  { revalidate: 120 },
);

export async function getMenuItems(input: {
  businessId: string;
  menuId: string;
  categoryId?: string | null;
  itemId?: string | null;
  q?: string | null;
  tag?: string | null;
}) {
  const allItems = await getMenuItemsCached(input.businessId, input.menuId);
  const query = input.q?.trim().toLowerCase() || '';
  const tag = input.tag?.trim().toLowerCase() || '';

  return allItems.filter((item) => {
    if (input.categoryId && item.category_id !== input.categoryId) return false;
    if (input.itemId && item.id !== input.itemId) return false;
    if (tag && !item.tagList.some((entry) => entry.toLowerCase() === tag)) return false;
    if (!query) return true;
    const haystack = [item.name, item.description, item.tagList.join(' ')]
      .filter(Boolean)
      .join(' ')
      .toLowerCase();
    return haystack.includes(query);
  });
}

const getMenuTranslationsCached = unstable_cache(
  async (entityIds: string[]) => {
    if (entityIds.length === 0) return [] as MenuTranslation[];

    const supabase = createSupabasePublicClient();
    const { data, error } = await supabase
      .from('menu_translations')
      .select('*')
      .in('entity_id', entityIds);

    if (error) {
      logger.warn('Failed to fetch menu translations', { entityIds, error });
      return [] as MenuTranslation[];
    }

    return (data ?? []) as MenuTranslation[];
  },
  ['public-menu-translations'],
  { revalidate: 300 },
);

export async function getMenuTranslations(entityIds: string[]) {
  return getMenuTranslationsCached(entityIds);
}

export async function getMenuItemVariants(menuItemId: string) {
  const supabase = createSupabasePublicClient();
  const { data, error } = await (supabase as unknown as {
    rpc: (
      fn: 'get_menu_item_variants_v1',
      args: Database['public']['Functions']['get_menu_item_variants_v1']['Args'],
    ) => Promise<{ data: MenuItemVariant[] | null; error: unknown }>;
  }).rpc('get_menu_item_variants_v1', {
    p_menu_item_id: menuItemId,
  });

  if (error) {
    logger.warn('Failed to fetch menu item variants', { menuItemId, error });
    return [] as MenuItemVariant[];
  }

  return (data ?? []) as MenuItemVariant[];
}

export async function getMenuItemPhotos(menuItemId: string) {
  const supabase = createSupabasePublicClient();
  const { data, error } = await (supabase as unknown as {
    rpc: (
      fn: 'get_menu_item_photos_v1',
      args: Database['public']['Functions']['get_menu_item_photos_v1']['Args'],
    ) => Promise<{ data: MenuItemPhoto[] | null; error: unknown }>;
  }).rpc('get_menu_item_photos_v1', {
    p_menu_item_id: menuItemId,
    p_limit: 8,
  });

  if (error) {
    logger.warn('Failed to fetch menu item photos', { menuItemId, error });
    return [] as MenuItemPhoto[];
  }

  return (data ?? []) as MenuItemPhoto[];
}

export type PriceHistoryEntry = {
  new_price_cents: number;
  old_price_cents: number | null;
  currency: string;
  source: string;
  created_at: string;
};

export async function getMenuItemPriceHistory(menuItemId: string): Promise<PriceHistoryEntry[]> {
  const supabase = createSupabasePublicClient();
  const supabaseAny = supabase as unknown as { from: (t: string) => any; rpc: (fn: string, args?: any) => any; storage: any; auth: any };
  try {
    const { data, error } = await supabaseAny.rpc('get_menu_item_price_history_v1', {
      p_menu_item_id: menuItemId,
      p_limit: 10,
    }) as { data: PriceHistoryEntry[] | null; error: unknown };
    if (error) return [];
    return data ?? [];
  } catch {
    return [];
  }
}

const getBusinessSocialLinksCached = unstable_cache(
  async (businessId: string): Promise<BusinessSocialLinks | null> => {
    const supabase = createSupabasePublicClient();
    try {
      const { data, error } = await supabase
        .from('business_social_links')
        .select('website,instagram,whatsapp,facebook,tiktok')
        .eq('business_id', businessId)
        .maybeSingle();

      if (error) return null;
      if (!data) return null;
      return data as BusinessSocialLinks;
    } catch {
      return null;
    }
  },
  ['public-business-social-links'],
  { revalidate: 300 },
);

export async function getPublicMenuData(businessSlugOrId: string): Promise<PublicMenuData | null> {
  const business = await getBusinessBySlugOrId(businessSlugOrId);
  if (!business) return null;

  const [businessHours, socialLinks, media, menu, presentation] = await Promise.all([
    getBusinessHoursInfo(business.id),
    getBusinessSocialLinksCached(business.id),
    getBusinessMedia(business),
    getMenuForBusiness(business.id),
    getResolvedBusinessPresentationSettings(business.id),
  ]);

  if (!menu) return null;

  const [sections, categories, items] = await Promise.all([
    getMenuSections(menu.id),
    getMenuCategories(business.id, menu.id),
    getMenuItems({ businessId: business.id, menuId: menu.id }),
  ]);

  const translations = await getMenuTranslations([
    business.id,
    ...categories.map((category) => category.id),
    ...items.map((item) => item.id),
  ]);

  return {
    business,
    businessHours,
    socialLinks,
    media: {
      ...media,
      logoUrl: presentation.logoUrl ?? media.logoUrl,
      coverUrl: presentation.coverUrl ?? media.coverUrl,
    },
    presentation,
    menu,
    sections,
    categories,
    items,
    translations,
  };
}
