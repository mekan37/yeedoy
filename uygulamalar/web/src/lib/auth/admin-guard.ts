import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';

/**
 * Server-side admin yetki kontrolü — defense-in-depth 2. katman.
 *
 * is_admin() RPC, admin_users tablosunu sorgular (tek yetkili kaynak).
 * Middleware'den bağımsız çalışır: middleware'i geçen ancak admin_users
 * kaydı olmayan kullanıcılar data helper katmanında bu guard ile bloke edilir.
 *
 * TUTARSIZLIK NOTU:
 *   middleware.ts → user_profiles.role kontrolü ('super_admin' | 'admin' | 'community_mod')
 *   is_admin() RPC → admin_users tablosu kontrolü
 *
 *   Bu iki kaynak kasıtlı defense-in-depth oluşturur:
 *   - user_profiles.role = 'community_mod' → middleware panel rotasını geçirir
 *   - admin_users tablosunda kaydı yoksa → is_admin() false → bu guard 403 döner
 *
 *   Uzun vadede middleware'in de admin_users tablosuna bağlanması önerilir.
 *   Ancak middleware Edge runtime'da çalıştığından önce migration testi gerekir.
 *
 * Kullanım (data helper'larda):
 *   const guard = await checkAdminAccess();
 *   if (!guard.authorized) return { items: [], total: 0 };
 */

export type AdminGuardResult =
  | { authorized: true; userId: string }
  | { authorized: false; status: 401 | 403 };

export async function checkAdminAccess(): Promise<AdminGuardResult> {
  const supabase = await createSupabaseServerClient();

  const {
    data: { user },
    error: authError,
  } = await supabase.auth.getUser();

  if (authError || !user) {
    return { authorized: false, status: 401 };
  }

  const sb = supabase as unknown as {
    rpc: (fn: string, args?: Record<string, unknown>) => Promise<{ data: unknown; error: unknown }>;
  };

  const { data: isAdmin, error: rpcError } = await sb.rpc('is_admin');

  if (rpcError || !isAdmin) {
    return { authorized: false, status: 403 };
  }

  return { authorized: true, userId: user.id };
}
