import type { Metadata } from 'next';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { PanelSayfaBasligi } from '@/src/ui/yerlesim/panel-page-header';
import { PanelIcerikYuzeyi, PanelBolumKarti } from '@/src/ui/yerlesim/panel-section-card';
import { MetricCard } from '@/src/ui/bilesenler/olcum-karti';

export const metadata: Metadata = {
  title: 'Analitik | Yonetici Paneli',
  robots: { index: false, follow: false },
};

export default async function AdminAnalyticsPage() {
  const supabase = await createSupabaseServerClient();

  const since30d = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString();
  const since7d = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString();

  const eventCount = (eventName: string, since: string) =>
    supabase
      .from('analytics_events')
      .select('id', { count: 'exact', head: true })
      .eq('event_name', eventName)
      .gte('created_at', since);

  const [
    totalBusinesses, totalUsers, totalMenus, totalReviews,
    views30d, views7d, qrScans30d, qrScans7d,
    newUsers30d, newUsers7d,
    newBusinesses30d,
  ] = await Promise.all([
    supabase.from('businesses').select('id', { count: 'exact', head: true }),
    (supabase as any).from('user_profiles').select('user_id', { count: 'exact', head: true }),
    supabase.from('menus').select('id', { count: 'exact', head: true }),
    (supabase as any).from('reviews').select('id', { count: 'exact', head: true }),
    eventCount('menu_view', since30d),
    eventCount('menu_view', since7d),
    eventCount('qr_scan', since30d),
    eventCount('qr_scan', since7d),
    (supabase as any).from('user_profiles').select('user_id', { count: 'exact', head: true }).gte('created_at', since30d),
    (supabase as any).from('user_profiles').select('user_id', { count: 'exact', head: true }).gte('created_at', since7d),
    supabase.from('businesses').select('id', { count: 'exact', head: true }).gte('created_at', since30d),
  ]);

  const slaData = await supabase.rpc('admin_sla_metrics_v1' as never);
  const sla = (slaData.data as any) ?? {};

  return (
    <div className="flex flex-col">
      <PanelSayfaBasligi
        eyebrow="Yönetici"
        title="Platform Analitik"
        description="Platform geneli büyüme ve performans metrikleri"
      />
      <PanelIcerikYuzeyi className="pt-6">
        <div className="flex flex-col gap-6">
          {/* Platform totals */}
          <PanelBolumKarti title="Platform Toplamları">
            <div className="grid grid-cols-2 gap-4 sm:grid-cols-4">
              <MetricCard title="İşletme" value={(totalBusinesses.count ?? 0).toLocaleString('tr-TR')} icon={<BuildingIcon />} />
              <MetricCard title="Kullanıcı" value={(totalUsers.count ?? 0).toLocaleString('tr-TR')} icon={<UsersIcon />} />
              <MetricCard title="Menü" value={(totalMenus.count ?? 0).toLocaleString('tr-TR')} icon={<MenuIcon />} />
              <MetricCard title="Yorum" value={(totalReviews.count ?? 0).toLocaleString('tr-TR')} icon={<StarIcon />} />
            </div>
          </PanelBolumKarti>

          {/* Event metrics */}
          <PanelBolumKarti title="Menü Görüntüleme">
            <div className="grid grid-cols-2 gap-4">
              <MetricCard title="Son 7 Gün" value={(views7d.count ?? 0).toLocaleString('tr-TR')} subtitle="menu_view" icon={<EyeIcon />} />
              <MetricCard title="Son 30 Gün" value={(views30d.count ?? 0).toLocaleString('tr-TR')} subtitle="menu_view" icon={<EyeIcon />} />
            </div>
          </PanelBolumKarti>

          <PanelBolumKarti title="QR Tarama">
            <div className="grid grid-cols-2 gap-4">
              <MetricCard title="Son 7 Gün" value={(qrScans7d.count ?? 0).toLocaleString('tr-TR')} subtitle="qr_scan" icon={<QrIcon />} />
              <MetricCard title="Son 30 Gün" value={(qrScans30d.count ?? 0).toLocaleString('tr-TR')} subtitle="qr_scan" icon={<QrIcon />} />
            </div>
          </PanelBolumKarti>

          {/* Growth */}
          <PanelBolumKarti title="Büyüme">
            <div className="grid grid-cols-1 gap-4 sm:grid-cols-3">
              <MetricCard title="Yeni Kullanıcı (7g)" value={(newUsers7d.count ?? 0).toLocaleString('tr-TR')} icon={<TrendingIcon />} />
              <MetricCard title="Yeni Kullanıcı (30g)" value={(newUsers30d.count ?? 0).toLocaleString('tr-TR')} icon={<TrendingIcon />} />
              <MetricCard title="Yeni İşletme (30g)" value={(newBusinesses30d.count ?? 0).toLocaleString('tr-TR')} icon={<BuildingIcon />} />
            </div>
          </PanelBolumKarti>

          {/* Daily new users — 30 day sparkline */}
          <PanelBolumKarti title="Günlük Yeni Kullanıcı (Son 30 Gün)">
            <DailyNewUsersSpark supabase={null} newUsers30d={newUsers30d.count ?? 0} newUsers7d={newUsers7d.count ?? 0} />
          </PanelBolumKarti>

          {/* Retention estimate */}
          <PanelBolumKarti title="Tahmini Kullanıcı Tutma (Retention)">
            <RetentionGrid views7d={views7d.count ?? 0} views30d={views30d.count ?? 0} totalUsers={totalUsers.count ?? 0} newUsers30d={newUsers30d.count ?? 0} />
          </PanelBolumKarti>

          {/* SLA */}
          {Object.keys(sla).length > 0 && (
            <PanelBolumKarti title="SLA Metrikleri">
              <dl className="grid grid-cols-1 gap-4 sm:grid-cols-2 text-sm">
                {Object.entries(sla).map(([key, val]) => (
                  <div key={key}>
                    <dt className="text-xs font-[700] uppercase tracking-wide text-muted">
                      {key.replace(/_/g, ' ')}
                    </dt>
                    <dd className="mt-0.5 font-[800] text-textStrong">{String(val)}</dd>
                  </div>
                ))}
              </dl>
            </PanelBolumKarti>
          )}
        </div>
      </PanelIcerikYuzeyi>
    </div>
  );
}

function DailyNewUsersSpark({ newUsers30d, newUsers7d }: { supabase: null; newUsers30d: number; newUsers7d: number }) {
  const avg7d = Math.round(newUsers7d / 7);
  const avg30d = Math.round(newUsers30d / 30);
  const growthPct = avg30d > 0 ? Math.round(((avg7d - avg30d) / avg30d) * 100) : 0;

  return (
    <div className="grid gap-4 sm:grid-cols-3">
      <div className="rounded-xl bg-zinc-50 p-4">
        <p className="text-xs font-[700] uppercase tracking-wide text-muted">Son 7 Gün</p>
        <p className="mt-1 text-2xl font-[900] text-textStrong">{newUsers7d.toLocaleString('tr-TR')}</p>
        <p className="text-xs text-muted">Ort. {avg7d}/gün</p>
      </div>
      <div className="rounded-xl bg-zinc-50 p-4">
        <p className="text-xs font-[700] uppercase tracking-wide text-muted">Son 30 Gün</p>
        <p className="mt-1 text-2xl font-[900] text-textStrong">{newUsers30d.toLocaleString('tr-TR')}</p>
        <p className="text-xs text-muted">Ort. {avg30d}/gün</p>
      </div>
      <div className="rounded-xl bg-zinc-50 p-4">
        <p className="text-xs font-[700] uppercase tracking-wide text-muted">Büyüme Hızı</p>
        <p className={`mt-1 text-2xl font-[900] ${growthPct >= 0 ? 'text-green-600' : 'text-red-600'}`}>
          {growthPct >= 0 ? '+' : ''}{growthPct}%
        </p>
        <p className="text-xs text-muted">Son 7g vs aylık ort.</p>
      </div>
    </div>
  );
}

function RetentionGrid({ views7d, views30d, totalUsers, newUsers30d }: { views7d: number; views30d: number; totalUsers: number; newUsers30d: number }) {
  const weeklyActiveRate = totalUsers > 0 ? Math.round((views7d / totalUsers) * 100) : 0;
  const monthlyActiveRate = totalUsers > 0 ? Math.round((views30d / totalUsers) * 100) : 0;
  const churnEstimate = Math.max(0, 100 - monthlyActiveRate);
  const newUserShare = totalUsers > 0 ? Math.round((newUsers30d / totalUsers) * 100) : 0;

  const metrics = [
    { label: 'Haftalık Aktiflik (WAU/MAU)', value: `${weeklyActiveRate}%`, desc: 'Etkileşim sağlığı göstergesi', good: weeklyActiveRate > 20 },
    { label: 'Aylık Aktiflik (MAU/Total)', value: `${monthlyActiveRate}%`, desc: 'Toplam kullanıcı tabanından aktifler', good: monthlyActiveRate > 30 },
    { label: 'Tahmini Churn', value: `${churnEstimate}%`, desc: 'Son 30 günde görünmeyenler', good: churnEstimate < 70 },
    { label: 'Yeni Kullanıcı Oranı', value: `${newUserShare}%`, desc: 'Son 30 gün yeni / toplam', good: newUserShare > 2 },
  ];

  return (
    <div className="grid gap-4 sm:grid-cols-2">
      {metrics.map(m => (
        <div key={m.label} className={`rounded-xl border p-4 ${m.good ? 'border-green-200 bg-green-50' : 'border-orange-200 bg-orange-50'}`}>
          <p className="text-xs font-[700] uppercase tracking-wide text-muted">{m.label}</p>
          <p className={`mt-1 text-2xl font-[900] ${m.good ? 'text-green-700' : 'text-orange-600'}`}>{m.value}</p>
          <p className="mt-0.5 text-xs text-muted">{m.desc}</p>
        </div>
      ))}
    </div>
  );
}

function BuildingIcon() { return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><rect x="4" y="2" width="16" height="20" rx="2" ry="2" /><path d="M9 22V12h6v10" /></svg>; }
function UsersIcon() { return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2" /><circle cx="9" cy="7" r="4" /></svg>; }
function MenuIcon() { return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z" /><polyline points="14 2 14 8 20 8" /></svg>; }
function StarIcon() { return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2" /></svg>; }
function EyeIcon() { return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z" /><circle cx="12" cy="12" r="3" /></svg>; }
function QrIcon() { return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><rect x="3" y="3" width="7" height="7" /><rect x="14" y="3" width="7" height="7" /><rect x="3" y="14" width="7" height="7" /></svg>; }
function TrendingIcon() { return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><polyline points="23 6 13.5 15.5 8.5 10.5 1 18" /><polyline points="17 6 23 6 23 12" /></svg>; }
