'use client';

import { useState } from 'react';
import { clsx } from 'clsx';
import { KampanyalarIstemcisi } from './kampanyalar-istemcisi';
import type { Kampanya } from './kampanya-formu';
import { EpostaSekmesi, type EpostaKampanyaOzet } from './eposta-sekmesi';

interface Stats {
  total_campaigns: number;
  active_campaigns: number;
  total_views: number;
  total_clicks: number;
  period_views: number;
  period_clicks: number;
}

interface Props {
  businessId: string;
  initialCampaigns: Kampanya[];
  initialTotal: number;
  stats: Stats;
  etiketler: string[];
  initialEmailKampanyalar: EpostaKampanyaOzet[];
}

type Sekme = 'kampanyalar' | 'eposta';

export function KampanyalarSayfaIstemcisi({
  businessId,
  initialCampaigns,
  initialTotal,
  stats,
  etiketler,
  initialEmailKampanyalar,
}: Props) {
  const [sekme, setSekme] = useState<Sekme>('kampanyalar');

  return (
    <div className="flex flex-col gap-5">
      <div className="flex gap-1 border-b border-border">
        <TabButton active={sekme === 'kampanyalar'} onClick={() => setSekme('kampanyalar')}>
          Kampanyalar
        </TabButton>
        <TabButton active={sekme === 'eposta'} onClick={() => setSekme('eposta')}>
          E-posta
        </TabButton>
      </div>

      {sekme === 'kampanyalar' ? (
        <KampanyalarIstemcisi
          businessId={businessId}
          initialCampaigns={initialCampaigns}
          initialTotal={initialTotal}
          stats={stats}
        />
      ) : (
        <EpostaSekmesi
          businessId={businessId}
          etiketler={etiketler}
          kampanyalar={initialCampaigns}
          initialEmailKampanyalar={initialEmailKampanyalar}
          onKampanyaOlusturTikla={() => setSekme('kampanyalar')}
        />
      )}
    </div>
  );
}

function TabButton({ active, onClick, children }: { active: boolean; onClick: () => void; children: React.ReactNode }) {
  return (
    <button
      type="button"
      onClick={onClick}
      className={clsx(
        'border-b-2 px-4 py-2.5 text-sm font-extrabold transition-colors',
        active ? 'border-primary text-primary' : 'border-transparent text-muted hover:text-textStrong',
      )}
    >
      {children}
    </button>
  );
}
