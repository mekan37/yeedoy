import type { Metadata } from 'next';
import { createSupabaseServerClient } from '@/src/lib/supabaseServer';
import { PanelPageHeader } from '@/src/ui/layout/panel-page-header';
import {
  buildHourBucketHeatmap,
  findBestDay,
  findBestHourRange,
  reservationStatusBreakdown,
} from '@/src/lib/veri/owner/analitik-yardimcilari';
import { AnalyticsClient } from './analytics-client';
import type { DailyPoint, TrafficSource, ActionMetric } from './analytics-client';

export const metadata: Metadata = {
  title: 'İstatistikler | Owner Panel',
  robots: { index: false, follow: false },
};

type Props = { searchParams: Promise<{ period?: string }> };

// Real source values → display labels
const SOURCE_LABELS: Record<string, string> = {
  web_next_public: 'Doğrudan',
  menu_page:       'Menü',
  discover:        'Keşfet',
  discover_search: 'Keşfet',
  discover_list:   'Keşfet',
};
const SRC_COLORS = ['#7f1d1d', '#dc2626', '#ef4444', '#fca5a5', '#fde8e8'];

export default async function OwnerAnalyticsPage({ searchParams }: Props) {
  const { period: periodParam } = await searchParams;
  const period = ['7d', '30d', '90d'].includes(periodParam ?? '') ? (periodParam as string) : '30d';
  const days = period === '7d' ? 7 : period === '90d' ? 90 : 30;

  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return null;

  const { data: claims } = await (supabase as any)
    .from('owner_claims')
    .select('business_id')
    .eq('user_id', user.id)
    .eq('status', 'approved') as { data: { business_id: string }[] | null };

  const businessIds = (claims ?? []).map((c) => c.business_id);

  if (businessIds.length === 0) {
    return (
      <div className="flex flex-col">
        <PanelPageHeader eyebrow="Owner" title="İstatistikler" description="İşletme performans analitiği" />
        <div className="px-6 pt-6">
          <div className="flex flex-col items-center justify-center rounded-2xl border border-dashed border-[#e5e7eb] bg-[#fafafa] py-20 text-center">
            <p className="text-base font-[800] text-[#1a1a2e]">İşletme bulunamadı</p>
            <p className="mt-1 text-sm text-[#94a3b8]">İstatistikleri görmek için önce bir işletme ekleyin.</p>
          </div>
        </div>
      </div>
    );
  }

  const now = Date.now();
  const since     = new Date(now - days * 86400000).toISOString();
  const sincePrev = new Date(now - 2 * days * 86400000).toISOString();

  const VIEW_EVENTS = ['menu_view', 'business_impression', 'menu_link_opened', 'business_page_view'];

  // ── Parallel queries ──────────────────────────────────────────────────────
  const [
    viewsCurr,   viewsPrev_,
    favCurr,     favPrev_,
    resPrev_,
    resStatusRows,
    // Full event rows for aggregation (line chart + traffic sources + hour heatmap)
    rawEvents,
  ] = await Promise.all([
    // KPI counts
    (supabase as any).from('analytics_events').select('id', { count: 'exact', head: true })
      .in('business_id', businessIds).in('event_name', VIEW_EVENTS).gte('created_at', since),
    (supabase as any).from('analytics_events').select('id', { count: 'exact', head: true })
      .in('business_id', businessIds).in('event_name', VIEW_EVENTS)
      .gte('created_at', sincePrev).lt('created_at', since),

    (supabase as any).from('favorites').select('id', { count: 'exact', head: true })
      .in('business_id', businessIds).gte('created_at', since),
    (supabase as any).from('favorites').select('id', { count: 'exact', head: true })
      .in('business_id', businessIds).gte('created_at', sincePrev).lt('created_at', since),

    (supabase as any).from('reservations').select('id', { count: 'exact', head: true })
      .in('business_id', businessIds).gte('created_at', sincePrev).lt('created_at', since),

    (supabase as any).from('reservations').select('status')
      .in('business_id', businessIds).gte('created_at', since).limit(10000),

    (supabase as any).from('analytics_events')
      .select('created_at, event_name, source')
      .in('business_id', businessIds)
      .gte('created_at', sincePrev)
      .limit(100000),
  ]);

  type RawEvent = { created_at: string; event_name: string; source: string | null };

  const allRaw: RawEvent[] = rawEvents.data ?? [];

  // Split into current and previous period
  const sinceMs = now - days * 86400000;
  const currRaw = allRaw.filter(e => new Date(e.created_at).getTime() >= sinceMs);
  const prevRaw = allRaw.filter(e => new Date(e.created_at).getTime() <  sinceMs);

  // ── Tekil olay adı sayımları (rawEvents'ten türetilir, ayrı sorgu yok) ────
  const countEvent = (rows: RawEvent[], eventName: string) =>
    rows.filter((e) => e.event_name === eventName).length;

  const profileCurrCount  = countEvent(currRaw, 'business_page_view');
  const profilePrevCount  = countEvent(prevRaw, 'business_page_view');
  const phoneCurrCount    = countEvent(currRaw, 'business_phone_click');
  const phonePrevCount    = countEvent(prevRaw, 'business_phone_click');
  const dirCurrCount      = countEvent(currRaw, 'business_directions_click');
  const dirPrevCount      = countEvent(prevRaw, 'business_directions_click');
  const menuViewCurrCount = countEvent(currRaw, 'menu_view');
  const menuViewPrevCount = countEvent(prevRaw, 'menu_view');
  const qrCurrCount       = countEvent(currRaw, 'qr_scanned');
  const qrPrevCount       = countEvent(prevRaw, 'qr_scanned');
  const shareCurrCount    = countEvent(currRaw, 'menu_shared');
  const sharePrevCount    = countEvent(prevRaw, 'menu_shared');

  // ── Daily line chart data ─────────────────────────────────────────────────
  const VIEW_SET = new Set(VIEW_EVENTS);
  const currDayMap: Record<string, number> = {};
  const prevDayMap: Record<string, number> = {};

  for (const e of currRaw) {
    if (VIEW_SET.has(e.event_name)) {
      const k = e.created_at.split('T')[0];
      currDayMap[k] = (currDayMap[k] ?? 0) + 1;
    }
  }
  for (const e of prevRaw) {
    if (VIEW_SET.has(e.event_name)) {
      const k = e.created_at.split('T')[0];
      prevDayMap[k] = (prevDayMap[k] ?? 0) + 1;
    }
  }

  const dailyData: DailyPoint[] = Array.from({ length: days }, (_, i) => {
    const d    = new Date(now - (days - 1 - i) * 86400000);
    const curr = d.toISOString().split('T')[0];
    const prev = new Date(d.getTime() - days * 86400000).toISOString().split('T')[0];
    return {
      label:    d.toLocaleDateString('tr-TR', { day: 'numeric', month: 'short' }),
      current:  currDayMap[curr] ?? 0,
      previous: prevDayMap[prev] ?? 0,
    };
  });

  // ── Traffic sources (current period) ─────────────────────────────────────
  const labelMap: Record<string, number> = {};
  for (const e of currRaw) {
    const label = SOURCE_LABELS[e.source ?? ''] ?? 'Diğer';
    labelMap[label] = (labelMap[label] ?? 0) + 1;
  }
  const srcTotal = Object.values(labelMap).reduce((a, b) => a + b, 0);
  const trafficSources: TrafficSource[] = Object.entries(labelMap)
    .sort((a, b) => b[1] - a[1])
    .map(([name, count], i) => ({
      name,
      count,
      value: srcTotal > 0 ? Math.round((count / srcTotal) * 1000) / 10 : 0,
      color: SRC_COLORS[Math.min(i, SRC_COLORS.length - 1)],
    }));

  // ── Popüler saatler: gün × 4 saatlik blok ısı haritası ────────────────────
  const hourBuckets = buildHourBucketHeatmap(
    currRaw.filter((e) => VIEW_SET.has(e.event_name)),
  );

  // ── Eylemler listesi ───────────────────────────────────────────────────────
  const actions: ActionMetric[] = [
    { key: 'menuViews',    value: menuViewCurrCount, prev: menuViewPrevCount },
    { key: 'qrScans',      value: qrCurrCount,       prev: qrPrevCount },
    { key: 'menuShares',   value: shareCurrCount,    prev: sharePrevCount },
    { key: 'reservations', value: (resStatusRows.data ?? []).length, prev: resPrev_.count ?? 0 },
  ];

  const reservationStatus = reservationStatusBreakdown(
    (resStatusRows.data ?? []) as { status: string }[],
  );

  const bestDay = findBestDay(dailyData);
  const bestHourRange = findBestHourRange(hourBuckets);
  const totalInteractions =
    (viewsCurr.count ?? 0) + (favCurr.count ?? 0) + phoneCurrCount + dirCurrCount;

  return (
    <div className="flex flex-col">
      <PanelPageHeader
        eyebrow="Owner"
        title="İstatistikler"
        description="İşletme performans analitiği — gerçek veriler"
      />
      <AnalyticsClient
        period={period}
        views={viewsCurr.count ?? 0}
        viewsPrev={viewsPrev_.count ?? 0}
        profileVisits={profileCurrCount}
        profileVisitsPrev={profilePrevCount}
        phoneCalls={phoneCurrCount}
        phoneCallsPrev={phonePrevCount}
        directions={dirCurrCount}
        directionsPrev={dirPrevCount}
        favorites={favCurr.count ?? 0}
        favoritesPrev={favPrev_.count ?? 0}
        dailyData={dailyData}
        trafficSources={trafficSources}
        reservationStatus={reservationStatus}
        hourBuckets={hourBuckets}
        bestDay={bestDay}
        bestHourRange={bestHourRange}
        actions={actions}
        totalInteractions={totalInteractions}
      />
    </div>
  );
}
