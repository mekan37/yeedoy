import type { Metadata } from 'next';
import { PanelPageHeader } from '@/src/ui/layout/panel-page-header';
import { PanelContentSurface } from '@/src/ui/layout/panel-section-card';
import { PanelEmptyState } from '@/src/ui/components/panel-empty-state';

export const metadata: Metadata = {
  title: 'Sadakat Programı | Owner Panel',
  robots: { index: false, follow: false },
};

export default async function OwnerLoyaltyPage() {
  return (
    <div className="flex flex-col">
      <PanelPageHeader
        eyebrow="Owner"
        title="Sadakat Programı"
        description="Müşterilerinizi ödüllendirin ve bağlılıklarını artırın"
      />
      <PanelContentSurface className="pt-6">
        <PanelEmptyState
          icon={<StarIcon />}
          title="Sadakat programı yakında"
          description="Puan bazlı ödül sistemi, üyelik kademeleri ve özel teklifler ile müşteri sadakatini artırın. Bu özellik yakında kullanıma açılacak."
        />
      </PanelContentSurface>
    </div>
  );
}

function StarIcon() {
  return (
    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2" />
    </svg>
  );
}
