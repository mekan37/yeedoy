import { redirect } from 'next/navigation';
import { createSupabaseServerClient } from './supabaseServer';

export async function getSessionUser() {
  const supabase = await createSupabaseServerClient();
  const { data } = await supabase.auth.getUser();
  return data.user;
}

export async function requireUser() {
  const user = await getSessionUser();
  if (!user) redirect('/login');
  return user;
}

export async function requireBusinessOwner(businessId: string) {
  const user = await requireUser();
  const supabase = await createSupabaseServerClient();

  const [{ data: isOwner }, { data: adminRow }] = await Promise.all([
    supabase.rpc('is_owner_of_business', { p_business_id: businessId }),
    supabase.from('admin_users').select('user_id').eq('user_id', user.id).maybeSingle(),
  ]);

  if (!isOwner && !adminRow) {
    redirect('/dashboard/businesses');
  }
  return user;
}
