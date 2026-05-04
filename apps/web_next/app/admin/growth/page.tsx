import type { Metadata } from 'next';
import { createSupabaseServerClient } from '@/src/lib/supabaseServer';
import { PanelPageHeader } from '@/src/ui/layout/panel-page-header';
import { PanelContentSurface, PanelSectionCard } from '@/src/ui/layout/panel-section-card';
import { MetricCard } from '@/src/ui/components/metric-card';

export const metadata: Metadata = {
  title: 'Büyüme | Admin Panel',
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
    (supabase as any).from('user_profiles').select('id', { count: 'exact', head: true }).gte('created_at', since7d),
    (supabase as any).from('user_profiles').select('id', { count: 'exact', head: true }).gte('created_at', since30d),
    (supabase as any).from('user_profiles').select('id', { count: 'exact', head: true }).gte('created_at', since90d),
    supabase.from('businesses').select('id', { count: 'exact', head: true }).gte('created_at', since7d),
    supabase.from('businesses').select('id', { count: 'exact', head: true }).gte('created_at', since30d),
    supabase.from('businesses').select('id', { count: 'exact', head: true }).gte('created_at', since90d),
    (supabase as any).from('business_reviews').select('id', { count: 'exact', head: true }).gte('created_at', since7d),
    (supabase as any).from('business_reviews').select('id', { count: 'exact', head: true }).gte('created_at', since30d),
    supabase.from('menus').select('id', { count: 'exact', head: true }).gte('created_at', since30d),
    (supabase as any).from('business_submissions').select('id', { count: 'exact', head: true }),
    supabase.rpc('admin_get_sponsorship_summary_v1' as never),
  ]);

  const sponsorship = (sponsorshipData.data as any) ?? {};

  return (
    <div className="flex flex-col">
      <PanelPageHeader
        eyebrow="Admin"
        title="Büyüme"
        description="Platform büyüme metrikleri ve kullanıcı edinimi"
      />
      <PanelContentSurface className="pt-6">
        <div className="flex flex-col gap-6">
          <PanelSectionCard title="Kullanıcı Büyümesi">
            <div className="grid grid-cols-1 gap-4 sm:grid-cols-3">
              <MetricCard title="Yeni Kullanıcı (7g)"  value={(newUsers7d.count  ?? 0).toLocaleString('tr-TR')} icon={<UsersIcon />} />
              <MetricCard title="Yeni Kullanıcı (30g)" value={(newUsers30d.count ?? 0).toLocaleString('tr-TR')} icon={<UsersIcon />} />
              <MetricCard title="Yeni Kullanıcı (90g)" value={(newUsers90d.count ?? 0).toLocaleString('tr-TR')} icon={<UsersIcon />} />
            </div>
          </PanelSectionCard>

          <PanelSectionCard title="İşletme Büyümesi">
            <div className="grid grid-cols-1 gap-4 sm:grid-cols-3">
              <MetricCard title="Yeni İşletme (7g)"   value={(newBiz7d.count  ?? 0).toLocaleString('tr-TR')} icon={<BuildingIcon />} />
              <MetricCard title="Yeni İşletme (30g)"  value={(newBiz30d.count ?? 0).toLocaleString('tr-TR')} icon={<BuildingIcon />} />
              <MetricCard title="Yeni İşletme (90g)"  value={(newBiz90d.count ?? 0).toLocaleString('tr-TR')} icon={<BuildingIcon />} />
            </div>
          </PanelSectionCard>

          <PanelSectionCard title="İçerik Büyümesi">
            <div className="grid grid-cols-1 gap-4 sm:grid-cols-3">
              <MetricCard title="Yeni Yorum (7g)"   value={(newReviews7d.count  ?? 0).toLocaleString('tr-TR')} icon={<StarIcon />} />
              <MetricCard title="Yeni Yorum (30g)"  value={(newReviews30d.count ?? 0).toLocaleString('tr-TR')} icon={<StarIcon />} />
              <MetricCard title="Yeni Menü (30g)"   value={(newMenus30d.count   ?? 0).toLocaleString('tr-TR')} icon={<MenuIcon />} />
            </div>
          </PanelSectionCard>

          <PanelSectionCard title="İşletme Başvuruları">
            <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
              <MetricCard title="Toplam Başvuru" value={(submissionsTotal.count ?? 0).toLocaleString('tr-TR')} icon={<FileTextIcon />} />
            </div>
          </PanelSectionCard>

          {Object.keys(sponsorship).length > 0 && (
            <PanelSectionCard title="Sponsorluk Özeti">
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
            </PanelSectionCard>
          )}
        </div>
      </PanelContentSurface>
    </div>
  );
}

function UsersIcon() { return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2" /><circle cx="9" cy="7" r="4" /></svg>; }
function BuildingIcon() { return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><rect x="4" y="2" width="16" height="20" rx="2" ry="2" /><path d="M9 22V12h6v10" /></svg>; }
function StarIcon() { return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2" /></svg>; }
function MenuIcon() { return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z" /><polyline points="14 2 14 8 20 8" /></svg>; }
function FileTextIcon() { return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z" /><polyline points="14 2 14 8 20 8" /><line x1="16" y1="13" x2="8" y2="13" /><line x1="16" y1="17" x2="8" y2="17" /><polyline points="10 9 9 9 8 9" /></svg>; }
