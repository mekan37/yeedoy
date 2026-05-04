import type { Metadata } from 'next';
import { PanelPageHeader } from '@/src/ui/layout/panel-page-header';
import { PanelContentSurface, PanelSectionCard } from '@/src/ui/layout/panel-section-card';
import { PanelEmptyState } from '@/src/ui/components/panel-empty-state';

export const metadata: Metadata = {
  title: 'Otomasyonlar | Owner Panel',
  robots: { index: false, follow: false },
};

export default function OwnerAutomationsPage() {
  return (
    <div className="flex flex-col">
      <PanelPageHeader
        eyebrow="Pazarlama"
        title="Otomasyonlar"
        description="Müşteri etkileşimlerini otomatikleştirin"
      />
      <PanelContentSurface className="pt-6">
        <PanelSectionCard>
          <PanelEmptyState
            icon={<ZapIcon />}
            title="Otomasyon motoru yakında"
            description="Tetikleyici tabanlı pazarlama otomasyonları yakında kullanıma açılacak. Doğum günü mesajları, sipariş sonrası takip ve daha fazlası."
          />
        </PanelSectionCard>
      </PanelContentSurface>
    </div>
  );
}

function ZapIcon() {
  return (
    <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <polygon points="13 2 3 14 12 14 11 22 21 10 12 10 13 2" />
    </svg>
  );
}
