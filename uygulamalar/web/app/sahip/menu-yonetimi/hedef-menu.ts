import { cookies } from 'next/headers';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { getOwnerBusinessIds } from '@/src/lib/veri/owner/sahip-isletmeleri';
import { AKTIF_ISLETME_COOKIE_NAME } from '@/src/ui/kabuk/aktif-isletme-cerezi';

/**
 * "Menü Yönetimi" nav grubu birden fazla menüsü olabilen bir işletme kavramını
 * tek bir düzenleyici sayfasına indirger: aktif işletmenin (çerezdeki seçim,
 * yoksa ilk işletme) en eski dahili menüsünü hedef alır. Menü yoksa null döner
 * — çağıran taraf menü listesi/oluşturma sayfasına yönlendirir.
 */
export async function resolveHedefMenuId(): Promise<string | null> {
  const supabase = await createSupabaseServerClient();
  const [{ data: { user } }, cookieStore] = await Promise.all([
    supabase.auth.getUser(),
    cookies(),
  ]);
  if (!user) return null;

  const businessIds = await getOwnerBusinessIds(supabase as any, user.id);
  if (businessIds.length === 0) return null;

  const cookieId = cookieStore.get(AKTIF_ISLETME_COOKIE_NAME)?.value;
  const businessId = cookieId && businessIds.includes(cookieId) ? cookieId : businessIds[0];

  const { data: menus } = await (supabase as any)
    .from('menus')
    .select('id, kind, created_at')
    .eq('business_id', businessId)
    .order('created_at', { ascending: true }) as { data: Array<{ id: string; kind: string | null }> | null };

  if (!menus || menus.length === 0) return null;

  const internal = menus.find((m) => m.kind === null || m.kind === 'internal');
  return (internal ?? menus[0]).id;
}
