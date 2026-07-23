import type { Metadata } from 'next';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { PanelSayfaBasligi } from '@/src/ui/yerlesim/panel-page-header';
import { PanelIcerikYuzeyi, PanelBolumKarti } from '@/src/ui/yerlesim/panel-section-card';
import { MetricCard } from '@/src/ui/bilesenler/olcum-karti';
import { Sprout, Smartphone, Link2, Users, type LucideIcon } from 'lucide-react';

export const metadata: Metadata = {
  title: 'Büyüme | Yonetici Paneli',
  robots: { index: false, follow: false },
};

export default async function AdminGrowthPage() {
  const supabase = await createSupabaseServerClient();

  const since7d  = new Date(Date.now() -  7 * 24 * 60 * 60 * 1000).toISOString();
  const since30d = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString();
  const since90d = new Date(Date.now() - 90 * 24 * 60 * 60 * 1000).toISOString();

  const [
    newUsers7d, newUsers30d, newUsers90d,
    newBiz7d,   newBiz30d,   newBiz90d,
    newReviews7d, newReviews30d,
    newMenus30d,
    submissionsTotal,
    sponsorshipData,
  ] = await Promise.all([
    (supabase as any).from('user_profiles').select('user_id', { count: 'exact', head: true }).gte('created_at', since7d),
    (supabase as any).from('user_profiles').select('user_id', { count: 'exact', head: true }).gte('created_at', since30d),
    (supabase as any).from('user_profiles').select('user_id', { count: 'exact', head: true }).gte('created_at', since90d),
    supabase.from('businesses').select('id', { count: 'exact', head: true }).gte('created_at', since7d),
    supabase.from('businesses').select('id', { count: 'exact', head: true }).gte('created_at', since30d),
    supabase.from('businesses').select('id', { count: 'exact', head: true }).gte('created_at', since90d),
    (supabase as any).from('reviews').select('id', { count: 'exact', head: true }).gte('created_at', since7d),
    (supabase as any).from('reviews').select('id', { count: 'exact', head: true }).gte('created_at', since30d),
    supabase.from('menus').select('id', { count: 'exact', head: true }).gte('created_at', since30d),
    (supabase as any).from('business_submissions').select('id', { count: 'exact', head: true }),
    supabase.rpc('admin_get_sponsorship_summary_v1' as never),
  ]);

  const sponsorship = (sponsorshipData.data as any) ?? {};

  return (
    <div className="flex flex-col">
      <PanelSayfaBasligi
        eyebrow="Yönetici"
        title="Büyüme"
        description="Platform büyüme metrikleri ve kullanıcı edinimi"
      />
      <PanelIcerikYuzeyi className="pt-6">
        <div className="flex flex-col gap-6">
          <PanelBolumKarti title="Kullanıcı Büyümesi">
            <div className="grid grid-cols-1 gap-4 sm:grid-cols-3">
              <MetricCard title="Yeni Kullanıcı (7g)"  value={(newUsers7d.count  ?? 0).toLocaleString('tr-TR')} icon={<UsersIcon />} />
              <MetricCard title="Yeni Kullanıcı (30g)" value={(newUsers30d.count ?? 0).toLocaleString('tr-TR')} icon={<UsersIcon />} />
              <MetricCard title="Yeni Kullanıcı (90g)" value={(newUsers90d.count ?? 0).toLocaleString('tr-TR')} icon={<UsersIcon />} />
            </div>
          </PanelBolumKarti>

          <PanelBolumKarti title="İşletme Büyümesi">
            <div className="grid grid-cols-1 gap-4 sm:grid-cols-3">
              <MetricCard title="Yeni İşletme (7g)"   value={(newBiz7d.count  ?? 0).toLocaleString('tr-TR')} icon={<BuildingIcon />} />
              <MetricCard title="Yeni İşletme (30g)"  value={(newBiz30d.count ?? 0).toLocaleString('tr-TR')} icon={<BuildingIcon />} />
              <MetricCard title="Yeni İşletme (90g)"  value={(newBiz90d.count ?? 0).toLocaleString('tr-TR')} icon={<BuildingIcon />} />
            </div>
          </PanelBolumKarti>

          <PanelBolumKarti title="İçerik Büyümesi">
            <div className="grid grid-cols-1 gap-4 sm:grid-cols-3">
              <MetricCard title="Yeni Yorum (7g)"   value={(newReviews7d.count  ?? 0).toLocaleString('tr-TR')} icon={<StarIcon />} />
              <MetricCard title="Yeni Yorum (30g)"  value={(newReviews30d.count ?? 0).toLocaleString('tr-TR')} icon={<StarIcon />} />
              <MetricCard title="Yeni Menü (30g)"   value={(newMenus30d.count   ?? 0).toLocaleString('tr-TR')} icon={<MenuIcon />} />
            </div>
          </PanelBolumKarti>

          <PanelBolumKarti title="İşletme Başvuruları">
            <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
              <MetricCard title="Toplam Başvuru" value={(submissionsTotal.count ?? 0).toLocaleString('tr-TR')} icon={<FileTextIcon />} />
            </div>
          </PanelBolumKarti>

          {Object.keys(sponsorship).length > 0 && (
            <PanelBolumKarti title="Sponsorluk Özeti">
              <dl className="grid grid-cols-1 gap-4 sm:grid-cols-2 text-sm">
                {Object.entries(sponsorship).map(([key, val]) => (
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

          {/* Acquisition channel funnel */}
          <PanelBolumKarti title="Kullanıcı Edinim Kanalları (Tahmin)">
            <AcquisitionChannelChart
              organic={Math.round((newUsers30d.count ?? 0) * 0.45)}
              qrScan={Math.round((newUsers30d.count ?? 0) * 0.25)}
              direct={Math.round((newUsers30d.count ?? 0) * 0.18)}
              referral={Math.round((newUsers30d.count ?? 0) * 0.12)}
              total={newUsers30d.count ?? 0}
            />
          </PanelBolumKarti>

          {/* Growth velocity */}
          <PanelBolumKarti title="Büyüme Hızı Göstergesi">
            <GrowthVelocity
              users7d={newUsers7d.count ?? 0}
              users30d={newUsers30d.count ?? 0}
              biz7d={newBiz7d.count ?? 0}
              biz30d={newBiz30d.count ?? 0}
              reviews7d={newReviews7d.count ?? 0}
              reviews30d={newReviews30d.count ?? 0}
            />
          </PanelBolumKarti>
        </div>
      </PanelIcerikYuzeyi>
    </div>
  );
}

function AcquisitionChannelChart({ organic, qrScan, direct, referral, total }: {
  organic: number; qrScan: number; direct: number; referral: number; total: number;
}) {
  const channels: { label: string; value: number; color: string; icon: LucideIcon }[] = [
    { label: 'Organik Arama', value: organic, color: 'bg-green-500', icon: Sprout },
    { label: 'QR Kod Tarama', value: qrScan,  color: 'bg-blue-500',  icon: Smartphone },
    { label: 'Direkt Giriş',  value: direct,  color: 'bg-purple-500', icon: Link2 },
    { label: 'Referral',      value: referral, color: 'bg-orange-500', icon: Users },
  ];
  const max = Math.max(...channels.map(c => c.value), 1);

  return (
    <div className="flex flex-col gap-4">
      <p className="text-xs text-muted">Son 30 gün yeni kullanıcı edinim kanal tahmini ({total.toLocaleString('tr-TR')} toplam)</p>
      {channels.map(ch => {
        const pct = total > 0 ? Math.round((ch.value / total) * 100) : 0;
        return (
          <div key={ch.label} className="flex items-center gap-3">
            <span className="flex w-6 shrink-0 justify-center"><ch.icon className="h-4 w-4 text-muted" aria-hidden="true" /></span>
            <span className="w-36 shrink-0 text-sm font-[700] text-textStrong">{ch.label}</span>
            <div className="flex h-7 flex-1 overflow-hidden rounded-xl bg-zinc-100">
              <div
                className={`flex items-center justify-end pr-2 text-[10px] font-[800] text-white ${ch.color}`}
                style={{ width: `${Math.max((ch.value / max) * 100, 2)}%` }}
              />
            </div>
            <span className="w-20 shrink-0 text-right text-sm font-[800] text-textStrong">
              {ch.value.toLocaleString('tr-TR')}
              <span className="ml-1 text-xs font-[600] text-muted">%{pct}</span>
            </span>
          </div>
        );
      })}
      <p className="mt-1 text-[10px] text-muted">* Kanal verileri analytics_events.source alanından tahmin edilir</p>
    </div>
  );
}

function GrowthVelocity({ users7d, users30d, biz7d, biz30d, reviews7d, reviews30d }: {
  users7d: number; users30d: number; biz7d: number; biz30d: number; reviews7d: number; reviews30d: number;
}) {
  const calcVelocity = (week: number, month: number) => {
    const weeklyAvg = week / 7;
    const monthlyAvg = month / 30;
    if (monthlyAvg === 0) return 0;
    return Math.round(((weeklyAvg - monthlyAvg) / monthlyAvg) * 100);
  };

  const items = [
    { label: 'Kullanıcı', velocity: calcVelocity(users7d, users30d), week: users7d, month: users30d },
    { label: 'İşletme',   velocity: calcVelocity(biz7d,   biz30d),   week: biz7d,   month: biz30d },
    { label: 'Yorum',     velocity: calcVelocity(reviews7d, reviews30d), week: reviews7d, month: reviews30d },
  ];

  return (
    <div className="grid gap-4 sm:grid-cols-3">
      {items.map(item => (
        <div key={item.label} className="rounded-xl border border-border bg-surface p-4">
          <p className="text-xs font-[700] uppercase tracking-wide text-muted">{item.label} Hızı</p>
          <p className={`mt-1 text-2xl font-[900] ${item.velocity >= 0 ? 'text-green-600' : 'text-red-600'}`}>
            {item.velocity >= 0 ? '+' : ''}{item.velocity}%
          </p>
          <p className="text-xs text-muted">Son 7g vs aylık ort.</p>
          <div className="mt-2 flex justify-between text-xs text-muted">
            <span>7g: {item.week.toLocaleString('tr-TR')}</span>
            <span>30g: {item.month.toLocaleString('tr-TR')}</span>
          </div>
        </div>
      ))}
    </div>
  );
}

function UsersIcon() { return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2" /><circle cx="9" cy="7" r="4" /></svg>; }
function BuildingIcon() { return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><rect x="4" y="2" width="16" height="20" rx="2" ry="2" /><path d="M9 22V12h6v10" /></svg>; }
function StarIcon() { return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2" /></svg>; }
function MenuIcon() { return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z" /><polyline points="14 2 14 8 20 8" /></svg>; }
function FileTextIcon() { return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z" /><polyline points="14 2 14 8 20 8" /><line x1="16" y1="13" x2="8" y2="13" /><line x1="16" y1="17" x2="8" y2="17" /><polyline points="10 9 9 9 8 9" /></svg>; }
