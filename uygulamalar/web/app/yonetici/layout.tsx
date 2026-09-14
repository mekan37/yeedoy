import type { Metadata } from 'next';
import type { ReactNode } from 'react';
import { redirect } from 'next/navigation';
import { YoneticiKabukIstemcisi } from '@/src/ui/kabuk/yonetici-kabuk-istemcisi';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { checkAdminAccess } from '@/src/lib/auth/admin-guard';

export const metadata: Metadata = {
  robots: { index: false, follow: false },
};

export default async function AdminLayout({ children }: { children: ReactNode }) {
  // Savunma-derinliği 2. katman — proxy.ts'in route-level guard'ı admin
  // subdomain rewrite'ını atlayabiliyordu (P0), bu katman rewrite'tan
  // etkilenmeden her /yonetici/** sayfası için ayrıca doğrulama yapar.
  const guard = await checkAdminAccess();
  if (!guard.authorized) {
    redirect(guard.status === 401 ? '/giris?redirect=/yonetici' : '/forbidden');
  }

  let bekleyenItirazSayisi = 0;
  let bekleyenKuyrukSayisi = 0;
  let bekleyenBildirimSayisi = 0;
  // İzinler önceden yalnızca client-side (useEffect + RPC) yükleniyordu —
  // ilk render'da permissions=null olduğu için kenar çubuğu bir an için
  // TÜM 30 bölümü gösterip sonra izinli olanlara daralıyordu (yetkisiz
  // bölümlerin varlığı bir anlığına da olsa sızıyordu). Artık layout
  // sunucu tarafında da aynı RPC'yi çağırıp ilk render'ı doğru state'le
  // yapıyor; istemci tarafı yalnızca tazeleme için hâlâ çalışıyor.
  let initialAdmin: { email: string | null; displayName: string; roleLabel: string; permissions: string[] } | null = null;
  try {
    const supabase = await createSupabaseServerClient();
    const sb = supabase;
    const [itirazRes, oneriRes, sahiplenmeRes, incelemeRes, userRes, roleRes] = await Promise.all([
      sb.from('moderation_appeals').select('id', { count: 'exact', head: true }).eq('status', 'pending'),
      sb.from('business_suggestions').select('id', { count: 'exact', head: true }).eq('status', 'pending'),
      sb.from('owner_claims').select('id', { count: 'exact', head: true }).eq('status', 'pending'),
      sb.from('business_submissions').select('id', { count: 'exact', head: true }).eq('status', 'new'),
      sb.auth.getUser(),
      (sb as unknown as { rpc: (fn: string) => Promise<{ data: unknown }> }).rpc('get_my_admin_role_v1'),
    ]);
    bekleyenItirazSayisi = itirazRes.count ?? 0;
    bekleyenKuyrukSayisi = (incelemeRes.count ?? 0) + (sahiplenmeRes.count ?? 0);
    bekleyenBildirimSayisi = bekleyenItirazSayisi + (oneriRes.count ?? 0) + bekleyenKuyrukSayisi;

    const user = userRes.data.user;
    const roleRow = (Array.isArray(roleRes.data) ? roleRes.data[0] : null) as { role_name?: string; permissions?: string[] } | null;
    if (user) {
      const localPart = user.email?.split('@')[0] ?? 'Admin';
      const displayName = localPart.charAt(0).toUpperCase() + localPart.slice(1);
      initialAdmin = {
        email: user.email ?? null,
        displayName,
        roleLabel: roleRow?.role_name ?? 'Yönetici',
        permissions: roleRow?.permissions ?? [],
      };
    }
  } catch {
    bekleyenItirazSayisi = 0;
    bekleyenKuyrukSayisi = 0;
    bekleyenBildirimSayisi = 0;
  }

  return (
    <YoneticiKabukIstemcisi
      bekleyenItirazSayisi={bekleyenItirazSayisi}
      bekleyenKuyrukSayisi={bekleyenKuyrukSayisi}
      bekleyenBildirimSayisi={bekleyenBildirimSayisi}
      initialAdmin={initialAdmin}
    >
      {children}
    </YoneticiKabukIstemcisi>
  );
}
