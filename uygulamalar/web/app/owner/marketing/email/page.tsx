import type { Metadata } from 'next';
import { PanelPageHeader } from '@/src/ui/layout/panel-page-header';
import { PanelContentSurface, PanelSectionCard } from '@/src/ui/layout/panel-section-card';
import { PanelEmptyState } from '@/src/ui/components/panel-empty-state';

export const metadata: Metadata = {
  title: 'E-posta Kampanyaları | Owner Panel',
  robots: { index: false, follow: false },
};

export default function OwnerEmailCampaignsPage() {
  return (
    <div className="flex flex-col">
      <PanelPageHeader
        eyebrow="Pazarlama"
        title="E-posta Kampanyaları"
        description="Müşterilerinize e-posta ile ulaşın"
      />
      <PanelContentSurface className="pt-6">
        <PanelSectionCard>
          <PanelEmptyState
            icon={<MailIcon />}
            title="E-posta kampanyaları yakında"
            description="E-posta pazarlama modülü yakında kullanıma açılacak. Müşterilerinize özel kampanyalar oluşturabileceksiniz."
          />
        </PanelSectionCard>
      </PanelContentSurface>
    </div>
  );
}

function MailIcon() {
  return (
    <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M4 4h16c1.1 0 2 .9 2 2v12c0 1.1-.9 2-2 2H4c-1.1 0-2-.9-2-2V6c0-1.1.9-2 2-2z" />
      <polyline points="22,6 12,13 2,6" />
    </svg>
  );
}
