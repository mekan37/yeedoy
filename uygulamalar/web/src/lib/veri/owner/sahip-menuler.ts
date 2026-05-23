import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { logger } from '@/src/lib/kayitci';
import type { Database } from '@/src/lib/taban/veri-tanimlari';
import { getOwnerBusinessIds, hasOwnerBusiness } from './sahip-isletmeleri';

type MenuRow = Database['public']['Tables']['menus']['Row'];
type MenuSectionRow = Database['public']['Tables']['menu_sections']['Row'];
type MenuItemRow = Database['public']['Tables']['menu_items']['Row'];

export type OwnerMenuSummary = {
  id: string;
  title: string;
  status: MenuRow['status'];
  business_id: string;
  created_at: string;
};

export type MenuWithSections = {
  menu: MenuRow;
  business: { id: string; name: string };
  sections: MenuSectionRow[];
  items: MenuItemRow[];
};

/**
 * Returns all menus belonging to businesses owned by the given userId.
 */
export async function getOwnerMenus(userId: string): Promise<OwnerMenuSummary[]> {
  const supabase = await createSupabaseServerClient();

  const businessIds = await getOwnerBusinessIds(supabase as any, userId);
  if (businessIds.length === 0) return [];

  const { data: menus, error: menuError } = await supabase
    .from('menus')
    .select('id,title,status,business_id,created_at')
    .in('business_id', businessIds)
    .order('created_at', { ascending: false });

  if (menuError) {
    logger.error('getOwnerMenus: failed to fetch menus', { userId, error: menuError });
    return [];
  }

  return (menus ?? []) as OwnerMenuSummary[];
}

/**
 * Returns the full menu with its sections and items, ownership-checked.
 * Returns null if the menu does not belong to a business owned by userId.
 */
export async function getMenuWithSections(
  menuId: string,
  userId: string,
): Promise<MenuWithSections | null> {
  const supabase = await createSupabaseServerClient();

  const { data: menu, error: menuError } = await supabase
    .from('menus')
    .select('*')
    .eq('id', menuId)
    .maybeSingle();

  if (menuError) {
    logger.error('getMenuWithSections: failed to fetch menu', { menuId, error: menuError });
    return null;
  }

  if (!menu) return null;

  const isOwner = await hasOwnerBusiness(supabase as any, userId, (menu as MenuRow).business_id);
  if (!isOwner) {
    return null;
  }

  const { data: business, error: bizError } = await supabase
    .from('businesses')
    .select('id,name')
    .eq('id', (menu as MenuRow).business_id)
    .maybeSingle();

  if (bizError) {
    logger.error('getMenuWithSections: failed to fetch business', { menuId, userId, error: bizError });
    return null;
  }

  if (!business) return null;

  const sectionsResult = await supabase
    .from('menu_sections')
    .select('*')
    .eq('menu_id', menuId)
    .order('sort_order', { ascending: true });

  const sectionIds = ((sectionsResult.data ?? []) as MenuSectionRow[]).map((section) => section.id);
  const itemsResult = sectionIds.length > 0
    ? await supabase
        .from('menu_items')
        .select('*')
        .in('section_id', sectionIds)
        .order('sort_order', { ascending: true })
    : { data: [], error: null };

  if (sectionsResult.error) {
    logger.warn('getMenuWithSections: failed to fetch sections', { menuId, error: sectionsResult.error });
  }
  if (itemsResult.error) {
    logger.warn('getMenuWithSections: failed to fetch items', { menuId, error: itemsResult.error });
  }

  return {
    menu: menu as MenuRow,
    business: business as { id: string; name: string },
    sections: (sectionsResult.data ?? []) as MenuSectionRow[],
    items: (itemsResult.data ?? []) as MenuItemRow[],
  };
}
