import { cache } from 'react';
import { logger } from '@/src/lib/kayitci';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';

// "8 paralel implementasyon" RBAC konsolidasyonu (2026-09-14): bu dosya
// önceden yalnızca owner_claims'e bakıyordu — business_team_memberships
// üzerinden eklenen ekip üyeleri (manager/editor/staff/viewer) TS
// tarafında "hiç işletmesi yokmuş" gibi görünüyordu. Artık her çağrı
// için AÇIK bir BusinessPermission ister ve gerçek yetki modelini
// (owner_claims ∪ chain_memberships ∪ business_team_memberships, DB'deki
// get_business_role_v1/has_business_permission_v1'in aynısı) kullanan
// has_business_permission_v1 / get_permitted_business_ids_v1 RPC'lerine
// delege eder — TS tarafında rol/rank mantığı YENİDEN yazılmıyor, tek
// gerçek kaynak DB'de kalıyor. `permission` parametresinin zorunlu
// olması bilinçli: her çağrı noktasının gerçekte hangi yetkiyi
// gerektirdiğini açıkça seçmesini TypeScript derleyicisi zorunlu kılıyor.
export type BusinessPermission =
  | 'business_read'
  | 'analytics_view'
  | 'media_upload'
  | 'qr_manage'
  | 'orders_manage'
  | 'menu_write'
  | 'business_write'
  | 'team_manage';

type SupabaseFromLike = {
  from: (table: string) => any;
};

type SupabaseRpcLike = SupabaseFromLike & {
  // Method shorthand (not an arrow-function-valued property) so this stays
  // bivariantly compatible with the generated SupabaseClient's overly-narrow
  // `rpc<FnName extends '...' | '...'>` literal-union signature.
  rpc(fn: string, args?: Record<string, unknown>): any;
};

export async function hasOwnerBusiness(
  supabase: SupabaseRpcLike,
  userId: string,
  businessId: string,
  permission: BusinessPermission,
): Promise<boolean> {
  const { data, error } = await supabase.rpc('has_business_permission_v1', {
    p_business_id: businessId,
    p_permission: permission,
  });

  if (error) {
    logger.warn('hasOwnerBusiness failed', { userId, businessId, permission, error });
    return false;
  }

  return Boolean(data);
}

// Sahip Paneli Güvenlik Denetimi P3: layout.tsx + her sayfa kendi
// createSupabaseServerClient() örneğini oluşturup bu fonksiyonu ayrı ayrı
// çağırıyordu — aynı render geçişinde aynı (userId, permission) için 2-4 kez
// tekrar DB round-trip'i. `supabase` argümanı çağıranlar arasında referans
// olarak farklı olduğundan doğrudan cache() sarmalayamıyoruz; bunun yerine
// gerçek sorguyu yalnızca (userId, permission) anahtarıyla React cache()'e
// alıyoruz — cache içinde kendi client'ını oluşturuyor (her istekte aynı
// cookie'lere bakan işlevsel olarak eşdeğer bir client).
const cachedGetPermittedBusinessIds = cache(async (
  userId: string,
  permission: BusinessPermission,
): Promise<string[]> => {
  const supabase = await createSupabaseServerClient();
  const { data, error } = await (supabase as unknown as SupabaseRpcLike).rpc('get_permitted_business_ids_v1', {
    p_permission: permission,
  });

  if (error) {
    logger.warn('getOwnerBusinessIds failed', { userId, permission, error });
    return [];
  }

  return Array.from(new Set((data ?? []) as string[]));
});

export async function getOwnerBusinessIds(
  _supabase: SupabaseRpcLike,
  userId: string,
  permission: BusinessPermission,
): Promise<string[]> {
  return cachedGetPermittedBusinessIds(userId, permission);
}

/**
 * `businesses` satırlarını, önceden bilinen bir işletme id listesinden çeker.
 * `owner_claims` sorgusunu tekrar çalıştırmaz — çağıran taraf id'leri zaten
 * biliyorsa (ör. `getOwnerBusinessIds` sonucu) bu fonksiyonu tercih etmeli.
 */
export async function getOwnerBusinessesByIds<T>(
  supabase: SupabaseFromLike,
  ids: string[],
  select: string,
): Promise<T[]> {
  if (ids.length === 0) return [];

  const { data, error } = await supabase
    .from('businesses')
    .select(select)
    .in('id', ids);

  if (error) {
    logger.warn('getOwnerBusinessesByIds failed', { error });
    return [];
  }

  return (data ?? []) as T[];
}

export async function getOwnerBusinesses<T>(
  supabase: SupabaseRpcLike,
  userId: string,
  select: string,
  permission: BusinessPermission,
): Promise<T[]> {
  const ids = await getOwnerBusinessIds(supabase, userId, permission);
  return getOwnerBusinessesByIds<T>(supabase, ids, select);
}
