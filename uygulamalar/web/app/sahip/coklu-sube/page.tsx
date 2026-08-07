import type { Metadata } from 'next';
import { redirect } from 'next/navigation';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { getOwnerBusinessIds } from '@/src/lib/veri/owner/sahip-isletmeleri';
import { PanelSayfaBasligi } from '@/src/ui/yerlesim/panel-page-header';
import { PanelIcerikYuzeyi } from '@/src/ui/yerlesim/panel-section-card';
import { CokluSubeIstemcisi } from './coklu-sube-istemcisi';
import { subeYonetimVerisiGetir } from './coklu-sube-islemleri';

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
  if (businessIds.length === 0) redirect('/sahip');

  const { data: chainedBusinesses } = await supabase
    .from('businesses')
    .select('id')
    .in('id', businessIds)
    .not('chain_id', 'is', null)
    .limit(1);

  const anchorBusinessId = chainedBusinesses?.[0]?.id ?? businessIds[0];

  const overviewResult = await subeYonetimVerisiGetir(anchorBusinessId);
  if ('error' in overviewResult) {
    throw new Error(overviewResult.error);
  }
  const overview = overviewResult;

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
