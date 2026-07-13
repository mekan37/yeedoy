import type { Metadata } from 'next';
import { createSupabaseServerClient } from '@/src/lib/supabaseServer';
import { PanelPageHeader } from '@/src/ui/layout/panel-page-header';
import { AnalyticsClient } from './analytics-client';
import type { DailyPoint, TrafficSource, HeatmapRow, HourlyPoint } from './analytics-client';

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

// JS DOW to display column index: display=[Pzt,Sal,Çar,Per,Cum,Cmt,Paz] → getDay()=[1,2,3,4,5,6,0]
const DOW_ORDER = [1, 2, 3, 4, 5, 6, 0];

function mkHeatmapRow(metric: string, rawByDow: number[]): HeatmapRow {
  const counts = DOW_ORDER.map((d) => rawByDow[d] ?? 0);
  const max = Math.max(...counts, 1);
  const norms = counts.map((c) => Math.round((c / max) * 100));
  return { metric, counts, norms };
}

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
  const since    = new Date(now - days * 86400000).toISOString();
  const sincePrev = new Date(now - 2 * days * 86400000).toISOString();

  const VIEW_EVENTS   = ['menu_view', 'business_impression', 'menu_link_opened', 'business_page_view'];
  const SEARCH_EVENTS = ['discovery_impression', 'business_impression'];

  // ── Parallel queries ──────────────────────────────────────────────────────
  const [
    viewsCurr, viewsPrev_,
    favCurr,   favPrev_,
    revCurr,   revPrev_,
    searchCurr, searchPrev_,
    // Full event rows for aggregation (line chart + heatmap + hourly + sources)
    rawEvents,
    // Favorites and reviews rows for DOW aggregation
    favRows,
    revRows,
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

    (supabase as any).from('business_reviews').select('id', { count: 'exact', head: true })
      .in('business_id', businessIds).eq('status', 'approved').gte('created_at', since),
    (supabase as any).from('business_reviews').select('id', { count: 'exact', head: true })
      .in('business_id', businessIds).eq('status', 'approved')
      .gte('created_at', sincePrev).lt('created_at', since),

    (supabase as any).from('analytics_events').select('id', { count: 'exact', head: true })
      .in('business_id', businessIds).in('event_name', SEARCH_EVENTS).gte('created_at', since),
    (supabase as any).from('analytics_events').select('id', { count: 'exact', head: true })
      .in('business_id', businessIds).in('event_name', SEARCH_EVENTS)
      .gte('created_at', sincePrev).lt('created_at', since),

    // Raw events for multi-purpose aggregation (last 2× period: curr + prev for line chart)
    (supabase as any).from('analytics_events')
      .select('created_at, event_name, source')
      .in('business_id', businessIds)
      .gte('created_at', sincePrev)
      .limit(100000),

    // Favorites rows for DOW heatmap
    (supabase as any).from('favorites')
      .select('created_at')
      .in('business_id', businessIds)
      .gte('created_at', since)
      .limit(50000),

    // Reviews rows for DOW heatmap
    (supabase as any).from('business_reviews')
      .select('created_at')
      .in('business_id', businessIds)
      .eq('status', 'approved')
      .gte('created_at', since)
      .limit(50000),
  ]);

  type RawEvent = { created_at: string; event_name: string; source: string | null };
  type DateRow  = { created_at: string };

  const allRaw: RawEvent[] = rawEvents.data ?? [];

  // Split into current and previous period
  const sinceMs = now - days * 86400000;
  const currRaw = allRaw.filter(e => new Date(e.created_at).getTime() >= sinceMs);
  const prevRaw = allRaw.filter(e => new Date(e.created_at).getTime() <  sinceMs);

  // ── Daily line chart data ─────────────────────────────────────────────────
  const VIEW_SET   = new Set(VIEW_EVENTS);
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
      value: srcTotal > 0 ? Math.round((count / srcTotal) * 1000) / 10 : 0,
      color: SRC_COLORS[Math.min(i, SRC_COLORS.length - 1)],
    }));

  // ── Hourly distribution (current period, view events) ────────────────────
  const hourMap = Array<number>(24).fill(0);
  for (const e of currRaw) {
    if (VIEW_SET.has(e.event_name)) {
      hourMap[new Date(e.created_at).getHours()]++;
    }
  }
  const hourlyData: HourlyPoint[] = hourMap.map((v, i) => ({
    h: i.toString().padStart(2, '0'),
    v,
  }));

  // ── Heatmap by day of week ────────────────────────────────────────────────
  const dowView:   number[] = Array(7).fill(0);
  const dowSearch: number[] = Array(7).fill(0);
  const dowFav:    number[] = Array(7).fill(0);
  const dowRev:    number[] = Array(7).fill(0);

  for (const e of currRaw) {
    const d = new Date(e.created_at).getDay();
    if (['menu_view', 'menu_link_opened'].includes(e.event_name))           dowView[d]++;
    if (['discovery_impression', 'business_impression'].includes(e.event_name)) dowSearch[d]++;
  }
  for (const f of (favRows.data ?? []) as DateRow[]) {
    dowFav[new Date(f.created_at).getDay()]++;
  }
  for (const r of (revRows.data ?? []) as DateRow[]) {
    dowRev[new Date(r.created_at).getDay()]++;
  }

  const heatmapRows: HeatmapRow[] = [
    mkHeatmapRow('Görüntülenme', dowView),
    mkHeatmapRow('Favori',       dowFav),
    mkHeatmapRow('Yorum',        dowRev),
    mkHeatmapRow('Arama',        dowSearch),
  ];

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
        favorites={favCurr.count ?? 0}
        favoritesPrev={favPrev_.count ?? 0}
        reviews={revCurr.count ?? 0}
        reviewsPrev={revPrev_.count ?? 0}
        directions={0}
        directionsPrev={0}
        searches={searchCurr.count ?? 0}
        searchesPrev={searchPrev_.count ?? 0}
        dailyData={dailyData}
        trafficSources={trafficSources}
        heatmapRows={heatmapRows}
        hourlyData={hourlyData}
      />
    </div>
  );
}
