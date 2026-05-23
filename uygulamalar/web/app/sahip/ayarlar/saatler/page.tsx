import type { Metadata } from 'next';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { getOwnerBusinesses } from '@/src/lib/veri/owner/sahip-isletmeleri';
import { PanelSayfaBasligi } from '@/src/ui/yerlesim/panel-page-header';
import { PanelIcerikYuzeyi, PanelBolumKarti } from '@/src/ui/yerlesim/panel-section-card';
import { PanelEmptyState } from '@/src/ui/bilesenler/panel-bos-durum';
import { HoursForm } from './saatler-formu';

export const metadata: Metadata = {
  title: 'Çalışma Saatleri | Sahip Paneli',
  robots: { index: false, follow: false },
};

export default async function OwnerHoursPage() {
  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();

  const list = user
    ? await getOwnerBusinesses<{ id: string; name: string; created_at: string | null }>(
      supabase as any,
      user.id,
      'id, name, created_at',
    )
    : [];

  list.sort((a, b) => (a.created_at ?? '').localeCompare(b.created_at ?? ''));

  if (list.length === 0) {
    return (
      <div className="flex flex-col">
        <PanelSayfaBasligi eyebrow="Ayarlar" title="Çalışma Saatleri" />
        <PanelIcerikYuzeyi className="pt-6">
          <PanelEmptyState
            icon={<ClockIcon />}
            title="Henüz işletme yok"
            description="Önce bir işletme ekleyin."
          />
        </PanelIcerikYuzeyi>
      </div>
    );
  }

  // Fetch hours for all businesses
  const { data: hoursRows } = await (supabase as any)
    .from('business_hours')
    .select('*')
    .in('business_id', list.map((b) => b.id)) as { data: Array<Record<string, unknown> & { business_id: string }> | null };

  const hoursMap = Object.fromEntries(
    (hoursRows ?? []).map((h) => [h.business_id, h]),
  );

  return (
    <div className="flex flex-col">
      <PanelSayfaBasligi
        eyebrow="Ayarlar"
        title="Çalışma Saatleri"
        description="Her gün için açılış ve kapanış saatlerini ayarlayın"
      />
      <PanelIcerikYuzeyi className="pt-6">
        <div className="flex flex-col gap-6">
          {list.map((b) => (
            <PanelBolumKarti key={b.id} title={b.name}>
              <HoursForm businessId={b.id} hours={hoursMap[b.id] as any ?? null} />
            </PanelBolumKarti>
          ))}
        </div>
      </PanelIcerikYuzeyi>
    </div>
  );
}

function ClockIcon() {
  return (
    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <circle cx="12" cy="12" r="10" /><polyline points="12 6 12 12 16 14" />
    </svg>
  );
}

