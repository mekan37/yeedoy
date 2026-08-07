import type { Metadata } from 'next';
import { redirect } from 'next/navigation';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { getOwnerBusinessIds } from '@/src/lib/veri/owner/sahip-isletmeleri';
import { PanelSayfaBasligi } from '@/src/ui/yerlesim/panel-page-header';
import { PanelIcerikYuzeyi } from '@/src/ui/yerlesim/panel-section-card';
import { CokluSubeIstemcisi } from './coklu-sube-istemcisi';
import type { CokluSubeOverview } from './coklu-sube-yardimcilari';

export const metadata: Metadata = {
  title: 'Çoklu Şube Yönetimi | Sahip Paneli',
  robots: { index: false, follow: false },
};

export default async function CokluSubeSayfasi() {
  const supabase = await createSupabaseServerClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) redirect('/giris?redirect=%2Fsahip%2Fcoklu-sube');

  const businessIds = await getOwnerBusinessIds(supabase, user.id);
  const anchorBusinessId = businessIds[0];
  if (!anchorBusinessId) redirect('/sahip');

  const { data: overviewData } = await (supabase as any).rpc('owner_get_chain_overview_v1', {
    p_business_id: anchorBusinessId,
  });
  const overview = (overviewData ?? {
    chain_id: null,
    chain_name: null,
    branches: [],
    total_views: 0,
    total_reservations: 0,
  }) as CokluSubeOverview;

  return (
    <div className="flex flex-col">
      <PanelSayfaBasligi
        eyebrow="Çoklu Şube"
        title="Çoklu Şube Yönetimi"
        description="Tüm şubelerinizi yönetin, performanslarını takip edin ve detaylara hızlıca erişin."
      />
      <PanelIcerikYuzeyi className="pt-6">
        <CokluSubeIstemcisi businessId={anchorBusinessId} initialOverview={overview} />
      </PanelIcerikYuzeyi>
    </div>
  );
}
