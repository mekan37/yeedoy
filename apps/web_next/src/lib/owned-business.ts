import { createSupabaseServerClient } from './supabaseServer';

type OwnerBusinessRow = {
  business_id: string;
  business_name: string;
  city: string;
  district: string;
};

export async function getOwnedBusinessByIdOrSlug(idOrSlug: string) {
  const supabase = await createSupabaseServerClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  const { data } = await supabase.rpc('owner_list_my_businesses_v2', {
    p_status: 'approved',
    p_limit: 500,
    p_offset: 0,
  });

  const rows = (data ?? []) as OwnerBusinessRow[];
  const byId = rows.find((r) => r.business_id === idOrSlug);
  if (byId) return byId;

  const { data: businessBySlug } = await supabase
    .from('businesses')
    .select('id,name,city,district,slug')
    .eq('slug', idOrSlug)
    .maybeSingle();
  if (businessBySlug) {
    const ownerRow = rows.find((r) => r.business_id === businessBySlug.id);
    if (ownerRow) return ownerRow;
  }

  if (!user) return null;

  const { data: adminRow } = await supabase
    .from('admin_users')
    .select('user_id')
    .eq('user_id', user.id)
    .maybeSingle();
  if (!adminRow) return null;

  const { data: byBusinessIdForAdmin } = await supabase
    .from('businesses')
    .select('id,name,city,district,slug')
    .eq('id', idOrSlug)
    .maybeSingle();

  const adminBusiness = byBusinessIdForAdmin ?? businessBySlug;
  if (!adminBusiness) return null;

  return {
    business_id: adminBusiness.id,
    business_name: adminBusiness.name,
    city: adminBusiness.city ?? '',
    district: adminBusiness.district ?? '',
  } as OwnerBusinessRow;
}
