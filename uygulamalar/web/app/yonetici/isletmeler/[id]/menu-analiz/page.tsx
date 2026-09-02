import type { Metadata } from 'next';
import { hasPermission } from '@/src/lib/yetki-kontrol';
import { PanelSayfaBasligi } from '@/src/ui/yerlesim/panel-page-header';
import { PanelIcerikYuzeyi } from '@/src/ui/yerlesim/panel-section-card';
import { YetkisizErisim } from '@/src/ui/bilesenler/yetkisiz-erisim';
import { isletmeDetayGetir } from '../../isletme-duzenle-islemleri';
import { MenuAnalizIstemcisi } from './menu-analiz-istemcisi';

export const metadata: Metadata = {
  title: 'Menü Analiz Et | Yönetici Paneli',
  robots: { index: false, follow: false },
};

type Props = {
  params: Promise<{ id: string }>;
  searchParams: Promise<{ job?: string }>;
};

export default async function MenuAnalizPage({ params, searchParams }: Props) {
  const yetkili = await hasPermission('page:isletmeler');
  if (!yetkili) {
    return (
      <div className="flex flex-col">
        <PanelSayfaBasligi eyebrow="Yönetici" title="Menü Analiz Et" description="Bu sayfayı görüntüleme yetkiniz yok." />
        <PanelIcerikYuzeyi className="pt-6">
          <YetkisizErisim sayfaAdi="Menü Analiz Et" />
        </PanelIcerikYuzeyi>
      </div>
    );
  }

  const { id: businessId } = await params;
  const { job } = await searchParams;
  const isletme = await isletmeDetayGetir(businessId);

  return (
    <div className="flex flex-col">
      <PanelSayfaBasligi
        eyebrow="Yönetici"
        title="Menü Analiz Et"
        description={
          isletme
            ? `${isletme.name} için yapay zeka destekli menü çıkarımı — hiçbir veri onaylamadan gerçek menüye yazılmaz.`
            : 'İşletme bulunamadı.'
        }
      />
      <PanelIcerikYuzeyi className="pt-6">
        <MenuAnalizIstemcisi businessId={businessId} businessName={isletme?.name ?? ''} initialJobId={job ?? null} />
      </PanelIcerikYuzeyi>
    </div>
  );
}
