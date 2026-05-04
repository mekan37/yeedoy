import type { Metadata } from 'next';
import { PanelPageHeader } from '@/src/ui/layout/panel-page-header';
import { PanelContentSurface } from '@/src/ui/layout/panel-section-card';
import { PanelEmptyState } from '@/src/ui/components/panel-empty-state';

export const metadata: Metadata = {
  title: 'Push Kampanyaları | Owner Panel',
  robots: { index: false, follow: false },
};

export default async function OwnerCampaignsPage() {
  return (
    <div className="flex flex-col">
      <PanelPageHeader
        eyebrow="Owner"
        title="Push Kampanyaları"
        description="Müşterilerinize anlık bildirim kampanyaları gönderin"
      />
      <PanelContentSurface className="pt-6">
        <PanelEmptyState
          icon={<BellIcon />}
          title="Push kampanyaları yakında"
          description="Push bildirim kampanyaları yakında eklenecek. Özel teklifler, etkinlikler ve duyurular için müşterilerinize doğrudan ulaşın."
        />
      </PanelContentSurface>
    </div>
  );
}

function BellIcon() {
  return (
    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9" />
      <path d="M13.73 21a2 2 0 0 1-3.46 0" />
    </svg>
  );
}
