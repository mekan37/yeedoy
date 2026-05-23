import type { Metadata } from 'next';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { PanelSayfaBasligi } from '@/src/ui/yerlesim/panel-page-header';
import { PanelIcerikYuzeyi, PanelBolumKarti } from '@/src/ui/yerlesim/panel-section-card';
import { MetricCard } from '@/src/ui/bilesenler/olcum-karti';

export const metadata: Metadata = {
  title: 'Finansal Yönetim | Admin Panel',
  robots: { index: false, follow: false },
};

type SponsorshipPackageRef = {
  name: string | null;
  price_cents: number | null;
  price_display?: string | null;
};

function getPackagePriceTry(pkg: SponsorshipPackageRef | null | undefined) {
  return (pkg?.price_cents ?? 0) / 100;
}

function revenueByMonth(sponsorships: Array<{ starts_at: string | null; sponsorship_packages: SponsorshipPackageRef | null }>) {
  const months: Record<string, number> = {};
  const now = new Date();
  for (let i = 5; i >= 0; i--) {
    const d = new Date(now.getFullYear(), now.getMonth() - i, 1);
    const key = `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}`;
    months[key] = 0;
  }
  for (const s of sponsorships) {
    if (!s.starts_at) continue;
    const key = s.starts_at.slice(0, 7);
    if (key in months) months[key] += getPackagePriceTry(s.sponsorship_packages);
  }
  return Object.entries(months).map(([month, revenue]) => ({ month, revenue }));
}

export default async function AdminFinansalYonetimPage() {
  const supabase = await createSupabaseServerClient();

  const now = Date.now();
  const since6m = new Date(now - 180 * 24 * 60 * 60 * 1000).toISOString();
  const currentMonthStart = new Date(new Date().getFullYear(), new Date().getMonth(), 1).toISOString();
  const prevMonthStart = new Date(new Date().getFullYear(), new Date().getMonth() - 1, 1).toISOString();
  const next7d = new Date(now + 7 * 24 * 60 * 60 * 1000).toISOString();

  const { data: sponsorPackages } = await (supabase as any)
    .from('sponsorship_packages')
    .select('id, name, surface, price_display, price_cents, currency_code, duration_days, is_active')
    .order('price_cents', { ascending: true }) as { data: Array<{
      id: string; name: string; surface: string; price_display: string | null; price_cents: number; currency_code: string; duration_days: number; is_active: boolean;
    }> | null };

  const { data: activeSponsorships } = await (supabase as any)
    .from('sponsorships')
    .select('id, business_id, package_id, starts_at, ends_at, status, businesses(name), sponsorship_packages(name, price_cents, price_display)')
    .eq('status', 'active')
    .order('starts_at', { ascending: false })
    .limit(50) as { data: Array<{
      id: string; business_id: string; package_id: string;
      starts_at: string | null; ends_at: string | null; status: string;
      businesses: { name: string } | null;
      sponsorship_packages: SponsorshipPackageRef | null;
    }> | null };

  // 6 months history for chart
  const { data: allSponsorships6m } = await (supabase as any)
    .from('sponsorships')
    .select('starts_at, sponsorship_packages(name, price_cents)')
    .gte('starts_at', since6m)
    .order('starts_at', { ascending: true }) as { data: Array<{
      starts_at: string | null;
      sponsorship_packages: SponsorshipPackageRef | null;
    }> | null };

  // Previous month
  const { data: prevMonthRev } = await (supabase as any)
    .from('sponsorships')
    .select('sponsorship_packages(price_cents)')
    .gte('starts_at', prevMonthStart)
    .lt('starts_at', currentMonthStart) as { data: Array<{ sponsorship_packages: SponsorshipPackageRef | null }> | null };

  // Current month
  const { data: monthlyRevenue } = await (supabase as any)
    .from('sponsorships')
    .select('sponsorship_packages(price_cents)')
    .gte('starts_at', currentMonthStart) as { data: Array<{ sponsorship_packages: SponsorshipPackageRef | null }> | null };

  // Upcoming renewals (expiring in 7 days)
  const { data: expiringRenewals } = await (supabase as any)
    .from('sponsorships')
    .select('id, ends_at, businesses(name), sponsorship_packages(name, price_cents, price_display)')
    .gte('ends_at', new Date().toISOString())
    .lte('ends_at', next7d)
    .order('ends_at', { ascending: true }) as { data: Array<{
      id: string; ends_at: string | null;
      businesses: { name: string } | null;
      sponsorship_packages: SponsorshipPackageRef | null;
    }> | null };

  const totalMonthly = (monthlyRevenue ?? []).reduce((s, r) => s + getPackagePriceTry(r.sponsorship_packages), 0);
  const totalPrevMonth = (prevMonthRev ?? []).reduce((s, r) => s + getPackagePriceTry(r.sponsorship_packages), 0);
  const momGrowth = totalPrevMonth > 0 ? Math.round(((totalMonthly - totalPrevMonth) / totalPrevMonth) * 100) : 0;
  const totalActiveSponsorships = (activeSponsorships ?? []).length;
  const avgPackagePrice = (sponsorPackages ?? []).filter(p => p.is_active).reduce((s, p, _, a) => s + (p.price_cents / 100) / a.length, 0);
  const renewalRevenue = (expiringRenewals ?? []).reduce((s, r) => s + getPackagePriceTry(r.sponsorship_packages), 0);

  // Revenue by month for chart
  const chartData = revenueByMonth(allSponsorships6m ?? []);
  const maxRev = Math.max(...chartData.map(d => d.revenue), 1);

  // Revenue by package breakdown
  const byPackage: Record<string, number> = {};
  for (const s of allSponsorships6m ?? []) {
    const name = s.sponsorship_packages?.name ?? 'Diğer';
    byPackage[name] = (byPackage[name] ?? 0) + getPackagePriceTry(s.sponsorship_packages);
  }

  return (
    <div className="flex flex-col">
      <PanelSayfaBasligi
        eyebrow="Admin"
        title="Finansal Yönetim"
        description="Platform geliri, sponsorluk paketleri, yenileme takvimi ve ödeme özeti"
        actions={
          /* eslint-disable-next-line @next/next/no-html-link-for-pages */
          <a
            href="/sunucu/yonetici/finansal-yonetim?export=csv"
            className="inline-flex items-center gap-1.5 rounded-xl border border-border bg-surface px-4 py-2 text-sm font-[700] text-muted hover:text-textStrong"
          >
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4" /><polyline points="7 10 12 15 17 10" /><line x1="12" y1="15" x2="12" y2="3" /></svg>
            CSV İndir
          </a>
        }
      />
      <PanelIcerikYuzeyi className="pt-6">
        <div className="flex flex-col gap-6">
          {/* Revenue KPIs */}
          <div className="grid grid-cols-2 gap-4 sm:grid-cols-4">
            <MetricCard title="Bu Ay Gelir" value={`₺${totalMonthly.toLocaleString('tr-TR')}`} icon={<TLIcon />}
              trend={momGrowth !== 0 ? { value: momGrowth, label: 'MoM' } : undefined}
            />
            <MetricCard title="Geçen Ay" value={`₺${totalPrevMonth.toLocaleString('tr-TR')}`} icon={<TrendIcon />} />
            <MetricCard title="Aktif Sponsorluk" value={totalActiveSponsorships} icon={<PackageIcon />} />
            <MetricCard
              title="Yakında Yenileme"
              value={`₺${renewalRevenue.toLocaleString('tr-TR')}`}
              subtitle={(expiringRenewals ?? []).length > 0 ? `${(expiringRenewals ?? []).length} sözleşme` : undefined}
              icon={<RefreshIcon />}
            />
          </div>

          {/* Revenue trend chart (6 months) */}
          <PanelBolumKarti title="6 Aylık Gelir Trendi">
            <div className="flex flex-col gap-2">
              <div className="flex items-end gap-2 h-32">
                {chartData.map(({ month, revenue }) => {
                  const pct = maxRev > 0 ? (revenue / maxRev) * 100 : 0;
                  const label = new Date(month + '-01').toLocaleDateString('tr-TR', { month: 'short' });
                  return (
                    <div key={month} className="flex flex-1 flex-col items-center gap-1">
                      <span className="text-[9px] font-[700] text-muted">₺{revenue >= 1000 ? `${Math.round(revenue / 1000)}K` : revenue}</span>
                      <div className="w-full rounded-t-md bg-primary/20 relative overflow-hidden" style={{ height: '80px' }}>
                        <div
                          className="absolute bottom-0 w-full rounded-t-md bg-primary transition-all"
                          style={{ height: `${pct}%` }}
                        />
                      </div>
                      <span className="text-[9px] text-muted">{label}</span>
                    </div>
                  );
                })}
              </div>

              {/* Revenue by package */}
              {Object.keys(byPackage).length > 0 && (
                <div className="mt-4">
                  <p className="mb-2 text-[10px] font-[800] uppercase tracking-wide text-muted">Paket Bazlı Dağılım (Son 6 Ay)</p>
                  <div className="flex flex-col gap-2">
                    {Object.entries(byPackage).sort((a, b) => b[1] - a[1]).map(([name, rev]) => {
                      const pct = Math.round((rev / (Object.values(byPackage).reduce((a, b) => a + b, 0))) * 100);
                      return (
                        <div key={name} className="flex items-center gap-3">
                          <span className="w-32 truncate text-xs text-muted">{name}</span>
                          <div className="flex-1 overflow-hidden rounded-full bg-zinc-100 h-2">
                            <div className="h-full rounded-full bg-primary" style={{ width: `${pct}%` }} />
                          </div>
                          <span className="w-16 text-right text-xs font-[700] text-textStrong">₺{rev.toLocaleString('tr-TR')}</span>
                          <span className="w-8 text-right text-[10px] text-muted">%{pct}</span>
                        </div>
                      );
                    })}
                  </div>
                </div>
              )}
            </div>
          </PanelBolumKarti>

          {/* Upcoming renewals */}
          {(expiringRenewals ?? []).length > 0 && (
            <PanelBolumKarti title="⚡ 7 Gün İçinde Yenileme Gerekli" noPadding>
              <table className="w-full text-sm">
                <thead>
                  <tr className="border-b border-border text-left bg-yellow-50 dark:bg-yellow-900/10">
                    <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">İşletme</th>
                    <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">Paket</th>
                    <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">Yenileme Tahmini</th>
                    <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">Bitiş</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-border">
                  {(expiringRenewals ?? []).map(r => (
                    <tr key={r.id} className="hover:bg-black/[0.02]">
                      <td className="px-5 py-3 font-[700] text-textStrong">{r.businesses?.name ?? '—'}</td>
                      <td className="px-5 py-3 text-muted">{r.sponsorship_packages?.name ?? '—'}</td>
                      <td className="px-5 py-3 font-[800] text-green-600">₺{getPackagePriceTry(r.sponsorship_packages).toLocaleString('tr-TR')}</td>
                      <td className="px-5 py-3">
                        <span className="inline-flex rounded-full bg-yellow-50 px-2 py-0.5 text-[10px] font-[700] text-yellow-700">
                          {r.ends_at ? new Date(r.ends_at).toLocaleDateString('tr-TR') : '—'}
                        </span>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </PanelBolumKarti>
          )}

          {/* Sponsor Packages */}
          <PanelBolumKarti title="Sponsorluk Paketleri" noPadding>
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b border-border text-left">
                  <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">Paket</th>
                  <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">Fiyat</th>
                  <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">Süre</th>
                  <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">Durum</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-border">
                {(sponsorPackages ?? []).map((pkg) => (
                  <tr key={pkg.id} className="hover:bg-black/[0.02]">
                    <td className="px-5 py-3 font-[700] text-textStrong">{pkg.name}</td>
                    <td className="px-5 py-3 font-[800] text-primary">
                      {pkg.price_display || new Intl.NumberFormat('tr-TR', {
                        style: 'currency',
                        currency: pkg.currency_code ?? 'TRY',
                        minimumFractionDigits: 0,
                      }).format(pkg.price_cents / 100)}
                    </td>
                    <td className="px-5 py-3 text-muted">{pkg.duration_days} gün</td>
                    <td className="px-5 py-3">
                      <span className={`inline-flex items-center rounded-full px-2 py-0.5 text-xs font-[700] ${pkg.is_active ? 'bg-green-50 text-green-700' : 'bg-zinc-100 text-zinc-500'}`}>
                        {pkg.is_active ? 'Aktif' : 'Pasif'}
                      </span>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </PanelBolumKarti>

          {/* Active Sponsorships */}
          <PanelBolumKarti title={`Aktif Sponsorluklar (${totalActiveSponsorships})`} noPadding>
            {(activeSponsorships ?? []).length === 0 ? (
              <p className="px-5 py-8 text-center text-sm text-muted">Aktif sponsorluk yok</p>
            ) : (
              <table className="w-full text-sm">
                <thead>
                  <tr className="border-b border-border text-left">
                    <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">İşletme</th>
                    <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">Paket</th>
                    <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">Ödeme</th>
                    <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">Başlangıç</th>
                    <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">Bitiş</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-border">
                  {(activeSponsorships ?? []).map((s) => {
                    const daysLeft = s.ends_at
                      ? Math.max(0, Math.ceil((new Date(s.ends_at).getTime() - Date.now()) / 86_400_000))
                      : null;
                    return (
                      <tr key={s.id} className="hover:bg-black/[0.02]">
                        <td className="px-5 py-3 font-[700] text-textStrong">{s.businesses?.name ?? '—'}</td>
                        <td className="px-5 py-3 text-muted">{s.sponsorship_packages?.name ?? '—'}</td>
                        <td className="px-5 py-3 font-[800] text-primary">₺{getPackagePriceTry(s.sponsorship_packages).toLocaleString('tr-TR')}</td>
                        <td className="px-5 py-3 text-xs text-muted">{s.starts_at ? new Date(s.starts_at).toLocaleDateString('tr-TR') : '—'}</td>
                        <td className="px-5 py-3">
                          <span className={`inline-flex rounded-full px-2 py-0.5 text-[10px] font-[700] ${daysLeft != null && daysLeft <= 7 ? 'bg-yellow-50 text-yellow-700' : 'bg-green-50 text-green-700'}`}>
                            {daysLeft != null ? `${daysLeft}g kaldı` : 'Bitiş yok'}
                          </span>
                        </td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            )}
          </PanelBolumKarti>
        </div>
      </PanelIcerikYuzeyi>
    </div>
  );
}

function TLIcon() {
  return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><line x1="12" y1="2" x2="12" y2="22" /><path d="M17 5H9.5a3.5 3.5 0 0 0 0 7h5a3.5 3.5 0 0 1 0 7H6" /></svg>;
}
function TrendIcon() {
  return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><polyline points="23 6 13.5 15.5 8.5 10.5 1 18" /><polyline points="17 6 23 6 23 12" /></svg>;
}
function PackageIcon() {
  return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M21 16V8a2 2 0 0 0-1-1.73l-7-4a2 2 0 0 0-2 0l-7 4A2 2 0 0 0 3 8v8a2 2 0 0 0 1 1.73l7 4a2 2 0 0 0 2 0l7-4A2 2 0 0 0 21 16z" /></svg>;
}
function RefreshIcon() {
  return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><polyline points="23 4 23 10 17 10" /><path d="M20.49 15a9 9 0 1 1-2.12-9.36L23 10" /></svg>;
}
