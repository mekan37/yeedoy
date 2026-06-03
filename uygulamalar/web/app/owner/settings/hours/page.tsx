import type { Metadata } from 'next';
import { createSupabaseServerClient } from '@/src/lib/supabaseServer';
import { PanelPageHeader } from '@/src/ui/layout/panel-page-header';
import { PanelContentSurface, PanelSectionCard } from '@/src/ui/layout/panel-section-card';
import { PanelEmptyState } from '@/src/ui/components/panel-empty-state';
import { HoursForm, type WeeklyHourRow } from './hours-form';

export const metadata: Metadata = {
  title: 'Çalışma Saatleri | Owner Panel',
  robots: { index: false, follow: false },
};

export default async function OwnerHoursPage() {
  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();

  const { data: businesses } = await (supabase as any)
    .from('businesses')
    .select('id, name')
    .eq('owner_id', user!.id)
    .order('created_at', { ascending: true }) as { data: Array<{ id: string; name: string }> | null };

  const list = businesses ?? [];

  if (list.length === 0) {
    return (
      <div className="flex flex-col">
        <PanelPageHeader eyebrow="Ayarlar" title="Çalışma Saatleri" />
        <PanelContentSurface className="pt-6">
          <PanelEmptyState
            icon={<ClockIcon />}
            title="Henüz işletme yok"
            description="Önce bir işletme ekleyin."
          />
        </PanelContentSurface>
      </div>
    );
  }

  // Fetch hours for all businesses via RPC (reads business_weekly_hours — the canonical table)
  const hoursMap = new Map<string, WeeklyHourRow[]>();
  await Promise.all(
    list.map(async (b) => {
      const { data } = await (supabase as any).rpc('get_business_hours_v1', {
        p_business_id: b.id,
      }) as { data: { weekly: WeeklyHourRow[]; special: unknown[]; is_open_now: boolean | null } | null };
      if (data?.weekly && data.weekly.length > 0) {
        hoursMap.set(b.id, data.weekly);
      }
    }),
  );

  return (
    <div className="flex flex-col">
      <PanelPageHeader
        eyebrow="Ayarlar"
        title="Çalışma Saatleri"
        description="Her gün için açılış ve kapanış saatlerini ayarlayın"
      />
      <PanelContentSurface className="pt-6">
        <div className="flex flex-col gap-6">
          {list.map((b) => (
            <PanelSectionCard key={b.id} title={b.name}>
              <HoursForm businessId={b.id} hours={hoursMap.get(b.id) ?? null} />
            </PanelSectionCard>
          ))}
        </div>
      </PanelContentSurface>
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
