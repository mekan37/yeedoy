import type { Metadata } from 'next';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { getOwnerBusinesses } from '@/src/lib/veri/owner/sahip-isletmeleri';
import { PanelSayfaBasligi } from '@/src/ui/yerlesim/panel-page-header';
import { PanelIcerikYuzeyi, PanelBolumKarti } from '@/src/ui/yerlesim/panel-section-card';
import { PanelEmptyState } from '@/src/ui/bilesenler/panel-bos-durum';
import { AlanAdiFormu } from './alan-adi-formu';
import { getDomainDurumu, type DomainDurumu } from './alan-adi-islemleri';

export const metadata: Metadata = {
  title: 'Ozel Domain | Sahip Paneli',
  robots: { index: false, follow: false },
};

export default async function OwnerSettingsDomainPage() {
  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();

  const list = user
    ? await getOwnerBusinesses<{ id: string; name: string }>(
      supabase as any,
      user.id,
      'id, name',
    )
    : [];

  // Pre-fetch domain status for each business
  const durumMap = new Map<string, DomainDurumu>();
  await Promise.all(
    list.map(async (b) => {
      const durum = await getDomainDurumu(b.id);
      durumMap.set(b.id, durum);
    }),
  );

  return (
    <div className="flex flex-col">
      <PanelSayfaBasligi
        eyebrow="Ayarlar"
        title="Ozel Domain"
        description="Isletmeleriniz icin ozel alan adi ayarlarini yonetin"
      />
      <PanelIcerikYuzeyi className="pt-6">
        {list.length === 0 ? (
          <PanelEmptyState
            icon={<GlobeIcon />}
            title="Isletme bulunamadi"
            description="Ozel domain eklemek icin once bir isletme olusturun."
          />
        ) : (
          <div className="flex flex-col gap-6">
            {list.map((b) => (
              <PanelBolumKarti key={b.id} title={b.name}>
                <AlanAdiFormu
                  businessId={b.id}
                  businessName={b.name}
                  initialDurum={durumMap.get(b.id) ?? null}
                />
              </PanelBolumKarti>
            ))}
          </div>
        )}
      </PanelIcerikYuzeyi>
    </div>
  );
}

function GlobeIcon() {
  return (
    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <circle cx="12" cy="12" r="10" />
      <line x1="2" y1="12" x2="22" y2="12" />
      <path d="M12 2a15.3 15.3 0 0 1 4 10 15.3 15.3 0 0 1-4 10 15.3 15.3 0 0 1-4-10 15.3 15.3 0 0 1 4-10z" />
    </svg>
  );
}
