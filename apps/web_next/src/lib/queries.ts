import { createSupabaseServerClient } from '@/src/lib/supabaseServer';

export async function getBusinessBySlug(slug: string) {
  const supabase = await createSupabaseServerClient();
  const { data } = await supabase
    .from('businesses')
    .select('*')
    .eq('slug', slug)
    .eq('is_active', true)
    .single();
  return data;
}

export async function getMenuByBusinessId(businessId: string) {
  const supabase = await createSupabaseServerClient();
  const [{ data: categories }, { data: items }] = await Promise.all([
    supabase
      .from('menu_categories')
      .select('*')
      .eq('business_id', businessId)
      .eq('is_active', true)
      .order('sort_order', { ascending: true }),
    supabase
      .from('menu_items')
      .select('*')
      .eq('business_id', businessId)
      .order('sort_order', { ascending: true }),
  ]);
  return { categories: categories ?? [], items: items ?? [] };
}
