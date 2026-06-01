'use server';

import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';

/**
 * Wraps a server action with explicit session validation.
 * Throws if no authenticated user — prevents unauthenticated direct POST calls
 * to server actions even when middleware doesn't cover the action endpoint.
 */
export async function withAuth<T>(fn: (userId: string) => Promise<T>): Promise<T> {
  const supabase = await createSupabaseServerClient();
  const { data: { user }, error } = await supabase.auth.getUser();
  if (error || !user) {
    throw new Error('Kimlik dogrulanamadi');
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
  if (authError || !user) throw new Error('Kimlik dogrulanamadi');

  const supabaseAny = supabase as unknown as { from: (t: string) => any; rpc: (fn: string, args?: any) => any; storage: any; auth: any };
  const { data: isAdmin } = await supabaseAny.rpc('is_admin') as { data: boolean | null };
  if (!isAdmin) throw new Error('Yasakli');

  return fn(user.id);
}
