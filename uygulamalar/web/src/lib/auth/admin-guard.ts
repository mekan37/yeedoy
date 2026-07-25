import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';

/**
 * Server-side admin yetki kontrolü — defense-in-depth 2. katman.
 *
 * Yetki kaynağı: public.admin_users tablosu (is_admin() RPC üzerinden).
 *
 * Mimari:
 *   proxy.ts        → is_admin() RPC ile route-level koruma (1. katman)
 *   checkAdminAccess() → is_admin() RPC ile data-layer koruma (2. katman)
 *
 * Her iki katman da aynı kaynağa (admin_users) bağlıdır. Proxy'yi atlayan
 * veya geçen bir istek bu guard ile ikinci kez doğrulanır.
 *
 * community_mod erişimi: admin_users kaydı olmayan community_mod kullanıcılar
 * her iki katmandan da geçemez. Bu ayrı bir yetki modeli (örn. is_admin_or_community_mod_v1)
 * gerektirirse açıkça tanımlanmalıdır.
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
