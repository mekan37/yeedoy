import type { Metadata } from 'next';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { hasPermission } from '@/src/lib/yetki-kontrol';
import { PanelSayfaBasligi } from '@/src/ui/yerlesim/panel-page-header';
import { PanelIcerikYuzeyi, PanelBolumKarti } from '@/src/ui/yerlesim/panel-section-card';
import { MetricCard } from '@/src/ui/bilesenler/olcum-karti';
import { YetkisizErisim } from '@/src/ui/bilesenler/yetkisiz-erisim';
import { AlertKonfigIstemci, type AlertRule } from './alert-konfig-istemci';

export const metadata: Metadata = {
  title: 'Gözlemlenebilirlik | Yonetici Paneli',
  robots: { index: false, follow: false },
};

export default async function AdminObservabilityPage() {
  const yetkili = await hasPermission('page:gozlemlenebilirlik');
  if (!yetkili) {
    return (
      <div className="flex flex-col">
        <PanelSayfaBasligi eyebrow="Yönetici" title="Gözlemlenebilirlik" description="Bu sayfayı görüntüleme yetkiniz yok." />
        <PanelIcerikYuzeyi className="pt-6"><YetkisizErisim sayfaAdi="Gözlemlenebilirlik" /></PanelIcerikYuzeyi>
      </div>
    );
  }

  const supabase = await createSupabaseServerClient();
  const sb = supabase as any;

  const since1h = new Date(Date.now() - 60 * 60 * 1000).toISOString();
  const since24h = new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString();

  const [
    events1h, events24h,
    rateLimit1h, rateLimit24h,
    slaRpc, recentEvents, activeUsersRes, alertRulesRes,
  ] = await Promise.all([
    supabase.from('analytics_events').select('id', { count: 'exact', head: true }).gte('created_at', since1h),
    supabase.from('analytics_events').select('id', { count: 'exact', head: true }).gte('created_at', since24h),
    sb.from('edge_rate_limit_events').select('id', { count: 'exact', head: true }).gte('created_at', since1h),
    sb.from('edge_rate_limit_events').select('id', { count: 'exact', head: true }).gte('created_at', since24h),
    supabase.rpc('admin_sla_metrics_v1' as never),
    supabase.from('analytics_events').select('event_name, created_at, business_id, source').order('created_at', { ascending: false }).limit(20),
    sb.from('analytics_events').select('user_id').gte('created_at', since24h).not('user_id', 'is', null).limit(5000),
    sb.from('admin_alert_rules').select('id, name, metric, threshold, severity, enabled, notify_email, notify_slack').order('created_at', { ascending: true }),
  ]);

  const sla = (slaRpc.data as any) ?? {};
  const latest = (recentEvents.data ?? []) as any[];
  const activeUsers24h = new Set(((activeUsersRes.data ?? []) as Array<{ user_id: string }>).map((r) => r.user_id)).size;
  const rules = (alertRulesRes.data ?? []) as AlertRule[];

  const liveValues: Record<AlertRule['metric'], number> = {
    event_rate_1h: events1h.count ?? 0,
    rate_limit_events_1h: rateLimit1h.count ?? 0,
    active_users_24h: activeUsers24h,
  };

  const breachedRules = rules.filter((r) => r.enabled && liveValues[r.metric] >= r.threshold);
  const criticalBreached = breachedRules.filter((r) => r.severity === 'critical').length;
  const warningBreached = breachedRules.filter((r) => r.severity === 'warning').length;

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
      <PanelSayfaBasligi
        eyebrow="Yönetici"
        title="Gözlemlenebilirlik"
        description="Platform sağlığı ve olay izleme"
      />
      <PanelIcerikYuzeyi className="pt-6">
        <div className="flex flex-col gap-6">
          <div className="grid grid-cols-2 gap-4 sm:grid-cols-3 lg:grid-cols-6">
            <MetricCard title="Olay (Son 1s)" value={(events1h.count ?? 0).toLocaleString('tr-TR')} icon={<ActivityIcon />} />
            <MetricCard title="Olay (Son 24s)" value={(events24h.count ?? 0).toLocaleString('tr-TR')} icon={<ActivityIcon />} />
            <MetricCard title="Aktif Kullanıcı (24s)" value={activeUsers24h.toLocaleString('tr-TR')} icon={<UsersIcon />} />
            <MetricCard title="Rate Limit (1s)" value={(rateLimit1h.count ?? 0).toLocaleString('tr-TR')} subtitle={`24s: ${(rateLimit24h.count ?? 0).toLocaleString('tr-TR')}`} icon={<ShieldIcon />} />
            <MetricCard title="Aktif Uyarı" value={breachedRules.length.toLocaleString('tr-TR')} subtitle={`${criticalBreached} kritik · ${warningBreached} uyarı`} icon={<AlertIcon />} />
            <MetricCard title="Kayıtlı Kural" value={rules.length.toLocaleString('tr-TR')} subtitle={`${rules.filter((r) => r.enabled).length} aktif`} icon={<BellIcon />} />
          </div>

          {/* SLA */}
          {Object.keys(sla).length > 0 && (
            <PanelBolumKarti title="SLA Metrikleri" description="Destek talebi/rapor işleme süreleri — altyapı gecikmesi değil, operasyonel SLA.">
              <dl className="grid grid-cols-1 gap-3 sm:grid-cols-2 text-sm">
                {Object.entries(sla).map(([key, val]) => (
                  <div key={key}>
                    <dt className="text-xs font-bold uppercase tracking-wide text-muted">{key.replace(/_/g, ' ')}</dt>
                    <dd className="mt-0.5 font-extrabold text-textStrong">{String(val)}</dd>
                  </div>
                ))}
              </dl>
            </PanelBolumKarti>
          )}

          {/* Event breakdown */}
          {sortedBreakdown.length > 0 && (
            <PanelBolumKarti title="Olay Dağılımı (Son 24s)" noPadding>
              <table className="w-full text-sm">
                <thead>
                  <tr className="border-b border-border text-left">
                    <th className="px-5 py-3 text-[11px] font-extrabold uppercase tracking-wide text-muted">Olay</th>
                    <th className="px-5 py-3 text-right text-[11px] font-extrabold uppercase tracking-wide text-muted">Sayı</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-border">
                  {sortedBreakdown.slice(0, 15).map(([name, cnt]) => (
                    <tr key={name}>
                      <td className="px-5 py-2.5 font-mono text-xs text-textStrong">{name}</td>
                      <td className="px-5 py-2.5 text-right font-extrabold text-textStrong">{cnt.toLocaleString('tr-TR')}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </PanelBolumKarti>
          )}

          {/* Active alerts + real health checks (no fabricated always-green checks) */}
          <PanelBolumKarti title="Sistem Sağlığı" description="Yalnızca gerçekten ölçülen metriklere dayanır — servis bazlı uptime/gecikme izleme bu platformda henüz kurulu değil.">
            <SystemHealthScore breachedRules={breachedRules} eventsPerHour1h={events1h.count ?? 0} eventsPerHour24hAvg={(events24h.count ?? 0) / 24} rateLimit1h={rateLimit1h.count ?? 0} />
          </PanelBolumKarti>

          {/* Alert configuration */}
          <PanelBolumKarti title="Uyarı Kuralları">
            <AlertKonfigIstemci rules={rules} liveValues={liveValues} />
          </PanelBolumKarti>

          {/* Recent events */}
          <PanelBolumKarti title="Son Olaylar" noPadding>
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b border-border text-left">
                  <th className="px-5 py-3 text-[11px] font-extrabold uppercase tracking-wide text-muted">Olay</th>
                  <th className="px-5 py-3 text-[11px] font-extrabold uppercase tracking-wide text-muted">Kaynak</th>
                  <th className="px-5 py-3 text-[11px] font-extrabold uppercase tracking-wide text-muted">Zaman</th>
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
          </PanelBolumKarti>
        </div>
      </PanelIcerikYuzeyi>
    </div>
  );
}

function SystemHealthScore({ breachedRules, eventsPerHour1h, eventsPerHour24hAvg, rateLimit1h }: {
  breachedRules: AlertRule[]; eventsPerHour1h: number; eventsPerHour24hAvg: number; rateLimit1h: number;
}) {
  const eventSpike = eventsPerHour24hAvg > 0 && eventsPerHour1h > eventsPerHour24hAvg * 3;
  const rateLimitSeverity = rateLimit1h > 100 ? 'critical' : rateLimit1h > 20 ? 'warning' : 'ok';

  const checks = [
    { label: 'Olay Hızı', status: eventSpike ? 'warning' : 'ok', detail: `${eventsPerHour1h} olay/1s (24s ortalaması: ${Math.round(eventsPerHour24hAvg)}/s)` },
    { label: 'Rate Limiting', status: rateLimitSeverity, detail: `${rateLimit1h} rate-limit vakası (son 1s)` },
    ...breachedRules.map((r) => ({ label: r.name, status: r.severity === 'critical' ? 'critical' : r.severity === 'warning' ? 'warning' : 'ok', detail: `Eşik aşıldı (${r.threshold})` })),
  ];

  const criticalCount = checks.filter((c) => c.status === 'critical').length;
  const warningCount = checks.filter((c) => c.status === 'warning').length;
  const healthScore = Math.max(0, 100 - criticalCount * 25 - warningCount * 10);

  return (
    <div className="flex flex-col gap-4">
      <div className="flex items-center gap-4">
        <div className={`flex h-16 w-16 items-center justify-center rounded-full text-xl font-black text-white ${healthScore >= 90 ? 'bg-green-500' : healthScore >= 70 ? 'bg-yellow-500' : 'bg-red-500'}`}>
          {healthScore}
        </div>
        <div>
          <p className="text-lg font-black text-textStrong">
            {healthScore >= 90 ? '✅ Sistem Sağlıklı' : healthScore >= 70 ? '⚠️ İzleme Gerekiyor' : '🔴 Kritik Durum'}
          </p>
          <p className="text-sm text-muted">{criticalCount} kritik · {warningCount} uyarı · {checks.filter((c) => c.status === 'ok').length} normal</p>
        </div>
      </div>
      <div className="grid gap-2 sm:grid-cols-2">
        {checks.map((c) => (
          <div key={c.label} className={`flex items-start gap-3 rounded-xl border p-3 ${c.status === 'ok' ? 'border-green-200 bg-green-50' : c.status === 'warning' ? 'border-yellow-200 bg-yellow-50' : 'border-red-200 bg-red-50'}`}>
            <span className="mt-0.5 text-base">{c.status === 'ok' ? '✅' : c.status === 'warning' ? '⚠️' : '🔴'}</span>
            <div>
              <p className="text-sm font-extrabold text-textStrong">{c.label}</p>
              <p className="text-xs text-muted">{c.detail}</p>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}

function ActivityIcon() { return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><polyline points="22 12 18 12 15 21 9 3 6 12 2 12" /></svg>; }
function ShieldIcon() { return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z" /></svg>; }
function UsersIcon() { return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2" /><circle cx="9" cy="7" r="4" /><path d="M23 21v-2a4 4 0 0 0-3-3.87" /><path d="M16 3.13a4 4 0 0 1 0 7.75" /></svg>; }
function AlertIcon() { return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M10.29 3.86 1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z" /><line x1="12" y1="9" x2="12" y2="13" /><line x1="12" y1="17" x2="12.01" y2="17" /></svg>; }
function BellIcon() { return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9" /><path d="M13.73 21a2 2 0 0 1-3.46 0" /></svg>; }
