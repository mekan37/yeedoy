import type { Metadata } from 'next';
import { createSupabaseServerClient } from '@/src/lib/supabaseServer';
import { PanelPageHeader } from '@/src/ui/layout/panel-page-header';
import { PanelContentSurface, PanelSectionCard } from '@/src/ui/layout/panel-section-card';
import { MetricCard } from '@/src/ui/components/metric-card';

export const metadata: Metadata = {
  title: 'Gözlemlenebilirlik | Admin Panel',
  robots: { index: false, follow: false },
};

export default async function AdminObservabilityPage() {
  const supabase = await createSupabaseServerClient();

  const since1h = new Date(Date.now() - 60 * 60 * 1000).toISOString();
  const since24h = new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString();

  const [
    events1h, events24h,
    rateLimitRes, slaRpc,
    recentEvents,
  ] = await Promise.all([
    supabase.from('analytics_events').select('id', { count: 'exact', head: true }).gte('created_at', since1h),
    supabase.from('analytics_events').select('id', { count: 'exact', head: true }).gte('created_at', since24h),
    (supabase as any)
      .from('edge_rate_limit_events')
      .select('id', { count: 'exact', head: true })
      .gte('created_at', since24h),
    supabase.rpc('admin_sla_metrics_v1' as never),
    supabase
      .from('analytics_events')
      .select('event_name, created_at, business_id, source')
      .order('created_at', { ascending: false })
      .limit(20),
  ]);

  const sla = (slaRpc.data as any) ?? {};
  const latest = (recentEvents.data ?? []) as any[];

  // Count by event name in last 24h
  const { data: eventBreakdown } = await supabase
    .from('analytics_events')
    .select('event_name')
    .gte('created_at', since24h)
    .limit(1000);

  const breakdown = ((eventBreakdown ?? []) as any[]).reduce<Record<string, number>>((acc, e) => {
    acc[e.event_name] = (acc[e.event_name] ?? 0) + 1;
    return acc;
  }, {});

  const sortedBreakdown = Object.entries(breakdown).sort(([, a], [, b]) => b - a);

  return (
    <div className="flex flex-col">
      <PanelPageHeader
        eyebrow="Admin"
        title="Gözlemlenebilirlik"
        description="Platform sağlığı ve olay izleme"
      />
      <PanelContentSurface className="pt-6">
        <div className="flex flex-col gap-6">
          <div className="grid grid-cols-1 gap-4 sm:grid-cols-3">
            <MetricCard title="Olay (Son 1s)" value={(events1h.count ?? 0).toLocaleString('tr-TR')} icon={<ActivityIcon />} />
            <MetricCard title="Olay (Son 24s)" value={(events24h.count ?? 0).toLocaleString('tr-TR')} icon={<ActivityIcon />} />
            <MetricCard title="Rate Limit (24s)" value={(rateLimitRes.count ?? 0).toLocaleString('tr-TR')} icon={<ShieldIcon />} />
          </div>

          {/* SLA */}
          {Object.keys(sla).length > 0 && (
            <PanelSectionCard title="SLA Metrikleri">
              <dl className="grid grid-cols-1 gap-3 sm:grid-cols-2 text-sm">
                {Object.entries(sla).map(([key, val]) => (
                  <div key={key}>
                    <dt className="text-xs font-[700] uppercase tracking-wide text-muted">{key.replace(/_/g, ' ')}</dt>
                    <dd className="mt-0.5 font-[800] text-textStrong">{String(val)}</dd>
                  </div>
                ))}
              </dl>
            </PanelSectionCard>
          )}

          {/* Event breakdown */}
          {sortedBreakdown.length > 0 && (
            <PanelSectionCard title="Olay Dağılımı (Son 24s)" noPadding>
              <table className="w-full text-sm">
                <thead>
                  <tr className="border-b border-border text-left">
                    <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">Olay</th>
                    <th className="px-5 py-3 text-right text-[11px] font-[800] uppercase tracking-wide text-muted">Sayı</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-border">
                  {sortedBreakdown.slice(0, 15).map(([name, cnt]) => (
                    <tr key={name}>
                      <td className="px-5 py-2.5 font-mono text-xs text-textStrong">{name}</td>
                      <td className="px-5 py-2.5 text-right font-[800] text-textStrong">{cnt.toLocaleString('tr-TR')}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </PanelSectionCard>
          )}

          {/* Recent events */}
          <PanelSectionCard title="Son Olaylar" noPadding>
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b border-border text-left">
                  <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">Olay</th>
                  <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">Kaynak</th>
                  <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">Zaman</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-border">
                {latest.map((e: any, i: number) => (
                  <tr key={i}>
                    <td className="px-5 py-2.5 font-mono text-xs text-textStrong">{e.event_name}</td>
                    <td className="px-5 py-2.5 text-xs text-muted">{e.source ?? '—'}</td>
                    <td className="px-5 py-2.5 text-xs text-muted">
                      {new Date(e.created_at).toLocaleTimeString('tr-TR')}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </PanelSectionCard>
        </div>
      </PanelContentSurface>
    </div>
  );
}

function ActivityIcon() {
  return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><polyline points="22 12 18 12 15 21 9 3 6 12 2 12" /></svg>;
}
function ShieldIcon() {
  return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z" /></svg>;
}
