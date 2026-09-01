import type { Metadata } from 'next';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { hasPermission } from '@/src/lib/yetki-kontrol';
import { PanelSayfaBasligi } from '@/src/ui/yerlesim/panel-page-header';
import { PanelIcerikYuzeyi } from '@/src/ui/yerlesim/panel-section-card';
import { YetkisizErisim } from '@/src/ui/bilesenler/yetkisiz-erisim';
import { KaraListeIstemcisi } from './kara-liste-istemcisi';
import type { BlacklistTerim } from './kara-liste-islemleri';

export const metadata: Metadata = {
  title: 'Kara Liste | Yönetici Paneli',
  robots: { index: false, follow: false },
};

export default async function KaraListePage() {
  const yetkili = await hasPermission('page:kara-liste');
  if (!yetkili) {
    return (
      <div className="flex flex-col">
        <PanelSayfaBasligi eyebrow="Yönetici" title="Kara Liste" description="Bu sayfayı görüntüleme yetkiniz yok." />
        <PanelIcerikYuzeyi className="pt-6"><YetkisizErisim sayfaAdi="Kara Liste" /></PanelIcerikYuzeyi>
      </div>
    );
  }

  const supabase = await createSupabaseServerClient();
  const sb = supabase as unknown as { rpc: (fn: string, args: Record<string, unknown>) => Promise<{ data: unknown; error: unknown }> };
  const { data } = await sb.rpc('admin_list_blacklist_terms_v1', { p_query: null, p_limit: 50, p_offset: 0 });
  const terimler: BlacklistTerim[] = Array.isArray(data) ? (data as BlacklistTerim[]) : [];

  return (
    <div className="flex flex-col">
      <PanelSayfaBasligi
        eyebrow="Yönetim"
        title="Kara Liste"
        description="Küfür/argo moderasyon kara listesini yönetin. Bu liste hem mobil hem web istemcilerin anlık ön-kontrolünde, hem de sunucu tarafı kesin kontrolde kullanılır."
      />
      <PanelIcerikYuzeyi className="pt-6">
        <KaraListeIstemcisi initialTerimler={terimler} />
      </PanelIcerikYuzeyi>
    </div>
  );
}
