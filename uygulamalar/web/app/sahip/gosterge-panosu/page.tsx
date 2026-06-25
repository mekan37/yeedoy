import type { Metadata } from 'next';
import Link from 'next/link';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { PanelSayfaBasligi } from '@/src/ui/yerlesim/panel-page-header';
import { PanelIcerikYuzeyi, PanelBolumKarti } from '@/src/ui/yerlesim/panel-section-card';
import { MetricCard } from '@/src/ui/bilesenler/olcum-karti';
import { getOwnerBusinessIds } from '@/src/lib/veri/owner/sahip-isletmeleri';

export const metadata: Metadata = {
  title: 'Genel Bakış | Sahip Paneli',
  robots: { index: false, follow: false },
};

function sparklinePath(values: number[], w = 300, h = 60): string {
  if (values.length < 2) return '';
  const max = Math.max(...values, 1);
  const min = Math.min(...values);
  const range = max - min || 1;
  const pts = values.map((v, i) => {
    const x = (i / (values.length - 1)) * w;
    const y = h - ((v - min) / range) * (h - 8) - 4;
    return `${x},${y}`;
  });
  return `M${pts.join(' L')}`;
}

type DashboardProps = { searchParams: Promise<{ bilgi?: string }> };

export default async function OwnerDashboardPage({ searchParams }: DashboardProps) {
  const { bilgi } = await searchParams;
  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();

  const bizIds = await getOwnerBusinessIds(supabase as any, user!.id);

  // Bekleyen talep var mı?
  const hasPendingClaim = bizIds.length === 0 && await (async () => {
    const { data } = await (supabase as any)
      .from('owner_claims')
      .select('id')
      .eq('user_id', user!.id)
      .eq('status', 'pending')
      .limit(1);
    return (data ?? []).length > 0;
  })();

  const since7d = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString();
  const since30d = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString();

  const [menusRes, qrScans30dRes, reviewsRes, views7d, views30d] = await Promise.all([
    bizIds.length > 0
      ? (supabase as any).from('menus').select('id', { count: 'exact', head: true }).in('business_id', bizIds) as Promise<{ count: number | null }>
      : Promise.resolve({ count: 0 }),
    bizIds.length > 0
      ? (supabase as any).from('analytics_events').select('id', { count: 'exact', head: true }).in('business_id', bizIds).eq('event_name', 'qr_scan').gte('created_at', since30d)
      : Promise.resolve({ count: 0 }),
    bizIds.length > 0
      ? (supabase as any).from('business_reviews').select('id', { count: 'exact', head: true }).in('business_id', bizIds).gte('created_at', since7d)
      : Promise.resolve({ count: 0 }),
    bizIds.length > 0
      ? (supabase as any).from('analytics_events').select('id', { count: 'exact', head: true }).in('business_id', bizIds).eq('event_name', 'menu_view').gte('created_at', since7d)
      : Promise.resolve({ count: 0 }),
    bizIds.length > 0
      ? (supabase as any).from('analytics_events').select('id', { count: 'exact', head: true }).in('business_id', bizIds).eq('event_name', 'menu_view').gte('created_at', since30d)
      : Promise.resolve({ count: 0 }),
  ]);

  const businessCount = bizIds.length;
  const menuCount = menusRes.count ?? 0;
  const qrScanCount30d = qrScans30dRes.count ?? 0;
  const reviewCount7d = reviewsRes.count ?? 0;
  const viewCount7d = views7d.count ?? 0;
  const viewCount30d = views30d.count ?? 0;

  // Daily QR scan counts for last 14 days sparkline
  const since14d = new Date(Date.now() - 14 * 24 * 60 * 60 * 1000).toISOString();
  const { data: qrScansByDay } = bizIds.length > 0
    ? await (supabase as any)
        .from('analytics_events')
        .select('created_at')
        .in('business_id', bizIds)
        .eq('event_name', 'qr_scan')
        .gte('created_at', since14d)
    : { data: [] };

  // Aggregate by day
  const dailyMap: Record<string, number> = {};
  for (let i = 13; i >= 0; i--) {
    const d = new Date(Date.now() - i * 86400000);
    dailyMap[d.toISOString().slice(0, 10)] = 0;
  }
  for (const e of (qrScansByDay ?? [])) {
    const day = (e.created_at as string).slice(0, 10);
    if (day in dailyMap) dailyMap[day] = (dailyMap[day] ?? 0) + 1;
  }
  const dailyValues = Object.values(dailyMap);
  const sparkPath = sparklinePath(dailyValues, 300, 60);

  // Daily view counts for last 7 days
  const { data: viewsByDay } = bizIds.length > 0
    ? await (supabase as any)
        .from('analytics_events')
        .select('created_at')
        .in('business_id', bizIds)
        .eq('event_name', 'menu_view')
        .gte('created_at', since7d)
    : { data: [] };

  const viewMap: Record<string, number> = {};
  for (let i = 6; i >= 0; i--) {
    const d = new Date(Date.now() - i * 86400000);
    viewMap[d.toISOString().slice(0, 10)] = 0;
  }
  for (const e of (viewsByDay ?? [])) {
    const day = (e.created_at as string).slice(0, 10);
    if (day in viewMap) viewMap[day] = (viewMap[day] ?? 0) + 1;
  }
  const viewDays = Object.entries(viewMap);
  const maxViews = Math.max(...viewDays.map(([, v]) => v), 1);

  return (
    <div className="flex flex-col">
      <PanelSayfaBasligi
        eyebrow="Owner"
        title="Genel Bakış"
        description="İşletmelerinizin özet durumu ve performans metrikleri"
      />
      <PanelIcerikYuzeyi className="pt-6">
        <div className="flex flex-col gap-6">
          {/* ── Onay bekleniyor banner ── */}
          {(hasPendingClaim || bilgi === 'talep_alindi' || bilgi === 'talep_bekliyor') && (
            <div className="rounded-2xl border border-amber-200 bg-amber-50 px-5 py-4">
              <div className="flex items-start gap-3">
                <span className="text-xl">⏳</span>
                <div>
                  <p className="font-[900] text-amber-900">
                    {bilgi === 'talep_alindi' ? 'Talebiniz alındı!' : 'Onay bekleniyor'}
                  </p>
                  <p className="mt-1 text-sm text-amber-800">
                    Sahiplenme talebiniz admin ekibimiz tarafından inceleniyor.
                    Onay sonrasında menü yayınlama ve tüm özellikler aktif olacak.
                    Bu süreçte paneli inceleyebilir, hazırlık yapabilirsiniz.
                  </p>
                </div>
              </div>
            </div>
          )}

          {/* ── Henüz işletme yok + talep da yok ── */}
          {!hasPendingClaim && bizIds.length === 0 && bilgi !== 'talep_alindi' && (
            <div className="rounded-2xl border border-border bg-bg px-5 py-5">
              <p className="font-[900] text-textStrong">İşletme bulunamadı</p>
              <p className="mt-1 text-sm text-muted">
                Henüz bir işletme eklemediniz veya sahiplenme talebiniz yok.
              </p>
              <Link
                href="/sahiplen/ara"
                className="mt-3 inline-flex rounded-xl border border-primary bg-primary/8 px-4 py-2 text-sm font-[800] text-primary hover:bg-primary/15"
              >
                İşletmemi Bul ve Sahiplen →
              </Link>
            </div>
          )}
          {/* KPI Grid */}
          <div className="grid grid-cols-2 gap-4 sm:grid-cols-4">
            <MetricCard title="İşletmeler" value={businessCount} icon={<BuildingIcon />} />
            <MetricCard title="Menüler" value={menuCount} icon={<MenuIcon />} />
            <MetricCard title="Son 30 Gün QR Tarama" value={qrScanCount30d} icon={<QrIcon />} />
            <MetricCard title="Son 7 Gün Yorum" value={reviewCount7d} icon={<StarIcon />} />
          </div>

          {/* QR scan sparkline + view bar chart side by side */}
          <div className="grid gap-4 lg:grid-cols-2">
            {/* QR scan trend */}
            <PanelBolumKarti title="QR Tarama Trendi (Son 14 Gün)">
              <div className="flex flex-col gap-2">
                <p className="text-2xl font-[900] text-primary">{qrScanCount30d.toLocaleString('tr-TR')}</p>
                <p className="text-xs text-muted">Son 30 gün toplam QR taraması</p>
                {sparkPath ? (
                  <svg viewBox="0 0 300 60" className="mt-2 w-full overflow-visible" preserveAspectRatio="none">
                    <defs>
                      <linearGradient id="sparkGrad" x1="0" y1="0" x2="0" y2="1">
                        <stop offset="0%" stopColor="var(--yd-color-primary)" stopOpacity="0.15" />
                        <stop offset="100%" stopColor="var(--yd-color-primary)" stopOpacity="0" />
                      </linearGradient>
                    </defs>
                    <path d={`${sparkPath} L300,60 L0,60 Z`} fill="url(#sparkGrad)" />
                    <path d={sparkPath} fill="none" stroke="var(--yd-color-primary)" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" />
                  </svg>
                ) : (
                  <p className="mt-4 text-sm text-muted">QR tarama verisi yok</p>
                )}
              </div>
            </PanelBolumKarti>

            {/* View bar chart */}
            <PanelBolumKarti title="Menü Görüntüleme (Son 7 Gün)">
              <div className="flex flex-col gap-2">
                <p className="text-2xl font-[900] text-blue-600">{viewCount7d.toLocaleString('tr-TR')}</p>
                <p className="text-xs text-muted">Son 7 günlük toplam menü görüntülemesi</p>
                <div className="mt-3 flex h-16 items-end gap-1">
                  {viewDays.map(([day, count]) => {
                    const pct = maxViews > 0 ? (count / maxViews) * 100 : 0;
                    const label = new Date(day).toLocaleDateString('tr-TR', { weekday: 'short' });
                    return (
                      <div key={day} className="group relative flex flex-1 flex-col items-center gap-1">
                        <div
                          className="w-full rounded-t-sm bg-blue-200 transition-colors group-hover:bg-blue-400"
                          style={{ height: `${Math.max(pct, 4)}%` }}
                          title={`${label}: ${count}`}
                        />
                        <span className="text-[9px] text-muted">{label.slice(0, 2)}</span>
                      </div>
                    );
                  })}
                </div>
                <p className="mt-1 text-xs text-muted">Son 30 gün: {viewCount30d.toLocaleString('tr-TR')} görüntülenme</p>
              </div>
            </PanelBolumKarti>
          </div>

          {/* Quick actions */}
          <PanelBolumKarti title="Hızlı Erişim">
            <div className="grid grid-cols-2 gap-3 sm:grid-cols-4">
              {[
                { href: '/sahip/yorumlar', label: `Yorumlar (${reviewCount7d} yeni)`, color: reviewCount7d > 0 ? 'text-blue-600' : '' },
                { href: '/sahip/analitik', label: 'Analitik', color: '' },
                { href: '/sahip/envanter', label: 'Envanter', color: '' },
                { href: '/sahip/menuler', label: 'Menüler', color: '' },
              ].map(a => (
                <a
                  key={a.href}
                  href={a.href}
                  className={`flex items-center justify-center rounded-xl border border-border p-3 text-center text-sm font-[700] hover:border-primary hover:text-primary transition-colors ${a.color}`}
                >
                  {a.label}
                </a>
              ))}
            </div>
          </PanelBolumKarti>
        </div>
      </PanelIcerikYuzeyi>
    </div>
  );
}

function BuildingIcon() {
  return (
    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <rect x="4" y="2" width="16" height="20" rx="2" ry="2" />
      <path d="M9 22V12h6v10" />
    </svg>
  );
}

function MenuIcon() {
  return (
    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z" />
      <polyline points="14 2 14 8 20 8" />
      <line x1="16" y1="13" x2="8" y2="13" />
      <line x1="16" y1="17" x2="8" y2="17" />
    </svg>
  );
}

function QrIcon() {
  return (
    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <rect x="3" y="3" width="7" height="7" /><rect x="14" y="3" width="7" height="7" /><rect x="3" y="14" width="7" height="7" />
    </svg>
  );
}

function StarIcon() {
  return (
    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2" />
    </svg>
  );
}
