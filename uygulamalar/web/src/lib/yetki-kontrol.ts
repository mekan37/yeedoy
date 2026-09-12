import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import type { AdminPermissionKey } from '@/src/lib/admin-izinler';
import { logger } from '@/src/lib/kayitci';

/** Server Component'lerde sayfa erişimi kontrolü için. route.ts'lerde is_admin() + RPC'nin kendi has_permission_v1 guard'ı yeterli, bu helper'a gerek yok. */
export async function hasPermission(permission: AdminPermissionKey): Promise<boolean> {
  const supabase = await createSupabaseServerClient();
  const sb = supabase as unknown as { rpc: (fn: string, args?: Record<string, unknown>) => Promise<{ data: unknown; error: { message?: string } | null }> };
  const { data, error } = await sb.rpc('has_permission_v1', { p_permission: permission });
  // error fail-closed olarak zaten güvenli (data===true değilse false döner)
  // ama önceden hiç loglanmıyordu — bir RPC hatası "yetkisiz" ile ayırt
  // edilemiyordu.
  if (error) logger.error('hasPermission: RPC hatası', { permission, message: error.message });
  return data === true;
}
