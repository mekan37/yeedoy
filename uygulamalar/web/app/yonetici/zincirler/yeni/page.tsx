import type { Metadata } from 'next';
import { PanelSayfaBasligi } from '@/src/ui/yerlesim/panel-page-header';
import { PanelIcerikYuzeyi } from '@/src/ui/yerlesim/panel-section-card';
import { ZincirOlusturFormu } from './zincir-olustur-formu';

export const metadata: Metadata = {
  title: 'Yeni Zincir | Yonetici Paneli',
  robots: { index: false, follow: false },
};

export default function AdminYeniZincirPage() {
  return (
    <div className="flex flex-col">
      <PanelSayfaBasligi
        eyebrow="Zincirler"
        title="Yeni Zincir Ekle"
        description="Yeni bir zincir markası oluşturun; şubeleri daha sonra işletme detayından bu zincire atayabilirsiniz."
      />
      <PanelIcerikYuzeyi className="pt-6 max-w-lg">
        <ZincirOlusturFormu />
      </PanelIcerikYuzeyi>
    </div>
  );
}
