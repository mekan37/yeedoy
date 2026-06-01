import { createSupabaseServerClient } from '@/src/lib/supabaseServer';
import { logger } from '@/src/lib/logger';
import type { Database } from '@/src/lib/supabase/database.types';

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
  sections: MenuSectionRow[];
  items: MenuItemRow[];
};

/**
 * Returns all menus belonging to businesses owned by the given userId.
 */
export async function getOwnerMenus(userId: string): Promise<OwnerMenuSummary[]> {
  const supabase = await createSupabaseServerClient();
  const supabaseAny = supabase as unknown as { from: (t: string) => any; rpc: (fn: string, args?: any) => any; storage: any; auth: any };

  // First resolve the businesses owned by this user.
  const { data: businesses, error: bizError } = await supabaseAny
    .from('businesses')
    .select('id')
    .eq('owner_id', userId);

  if (bizError) {
    logger.error('getOwnerMenus: failed to fetch businesses', { userId, error: bizError });
    return [];
  }

  const businessIds = ((businesses ?? []) as Array<{ id: string }>).map((b) => b.id);
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

  // Ownership check — verify the menu's business belongs to userId.
  const { data: business, error: bizError } = await supabase
    .from('businesses')
    .select('id')
    .eq('id', (menu as MenuRow).business_id)
    .eq('owner_id', userId)
    .maybeSingle();

  if (bizError) {
    logger.error('getMenuWithSections: ownership check failed', { menuId, userId, error: bizError });
    return null;
  }

  if (!business) {
    // Not owned by this user.
    return null;
  }

  const [sectionsResult, itemsResult] = await Promise.all([
    supabase
      .from('menu_sections')
      .select('*')
      .eq('menu_id', menuId)
      .order('sort_order', { ascending: true }),
    supabase
      .from('menu_items')
      .select('*')
      .eq('business_id', (menu as MenuRow).business_id)
      .order('sort_order', { ascending: true }),
  ]);

  if (sectionsResult.error) {
    logger.warn('getMenuWithSections: failed to fetch sections', { menuId, error: sectionsResult.error });
  }
  if (itemsResult.error) {
    logger.warn('getMenuWithSections: failed to fetch items', { menuId, error: itemsResult.error });
  }

  return {
    menu: menu as MenuRow,
    sections: (sectionsResult.data ?? []) as MenuSectionRow[],
    items: (itemsResult.data ?? []) as MenuItemRow[],
  };
}
