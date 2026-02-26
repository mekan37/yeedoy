import { createSupabaseServerClient } from './supabaseServer';

export async function canManageBusiness(
  supabase: Awaited<ReturnType<typeof createSupabaseServerClient>>,
  userId: string,
  businessId: string,
) {
  const [{ data: isOwner }, { data: adminRow }] = await Promise.all([
    supabase.rpc('is_owner_of_business', { p_business_id: businessId }),
    supabase.from('admin_users').select('user_id').eq('user_id', userId).maybeSingle(),
  ]);

  return Boolean(isOwner || adminRow);
}
