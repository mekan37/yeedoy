'use server';

import { createSupabaseServerClient } from '@/src/lib/supabaseServer';

/**
 * Wraps a server action with explicit session validation.
 * Throws if no authenticated user — prevents unauthenticated direct POST calls
 * to server actions even when middleware doesn't cover the action endpoint.
 */
export async function withAuth<T>(fn: (userId: string) => Promise<T>): Promise<T> {
  const supabase = await createSupabaseServerClient();
  const { data: { user }, error } = await supabase.auth.getUser();
  if (error || !user) {
    throw new Error('Unauthorized');
  }
  return fn(user.id);
}

/**
 * Wraps a server action with admin role validation.
 * Throws if user is not authenticated or does not have an admin role.
 */
export async function withAdminAuth<T>(fn: (userId: string) => Promise<T>): Promise<T> {
  const supabase = await createSupabaseServerClient();
  const { data: { user }, error: authError } = await supabase.auth.getUser();
  if (authError || !user) throw new Error('Unauthorized');

  const { data: profile } = await (supabase as any)
    .from('user_profiles')
    .select('role')
    .eq('id', user.id)
    .single() as { data: { role: string } | null };

  const adminRoles = ['super_admin', 'admin', 'community_mod'];
  if (!profile || !adminRoles.includes(profile.role)) {
    throw new Error('Forbidden');
  }

  return fn(user.id);
}
