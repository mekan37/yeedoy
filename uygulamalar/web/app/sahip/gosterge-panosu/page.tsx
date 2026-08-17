import type { Metadata } from 'next';
import Link from 'next/link';
import { Clock } from 'lucide-react';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { PanelSayfaBasligi } from '@/src/ui/yerlesim/panel-page-header';
import { PanelIcerikYuzeyi, PanelBolumKarti } from '@/src/ui/yerlesim/panel-section-card';
import { MetricCard } from '@/src/ui/bilesenler/olcum-karti';
import { getOwnerBusinessIds, getOwnerBusinessesByIds } from '@/src/lib/veri/owner/sahip-isletmeleri';
import { buildMenuImageUrl } from '@/src/lib/medya-adresi';

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

function pctChange(curr: number, prev: number) {
  if (prev === 0) return curr > 0 ? 100 : 0;
  return Math.round(((curr - prev) / prev) * 100);
}

function timeAgo(iso: string) {
  const diff = Date.now() - new Date(iso).getTime();
  const m = Math.floor(diff / 60000);
  if (m < 1) return 'az önce';
  if (m < 60) return `${m} dk önce`;
  const h = Math.floor(m / 60);
  if (h < 24) return `${h} saat önce`;
  const d = Math.floor(h / 24);
  if (d < 30) return `${d} gün önce`;
  return new Date(iso).toLocaleDateString('tr-TR');
}

type BizRow = {
  id: string;
  name: string;
  slug: string | null;
  category: string | null;
  logo_url: string | null;
  cover_url: string | null;
  is_verified: boolean | null;
  is_active: boolean | null;
};

type ReviewRow = {
  id: string;
  business_id: string;
  user_id: string | null;
  rating: number;
  content: string | null;
  status: string;
  created_at: string;
  owner_reply: string | null;
  owner_replied_at: string | null;
};

type TrendCount = { curr: number; prev: number };

type DashboardProps = {
  searchParams: Promise<{ bilgi?: string; isletme?: string | string[] }>;
};

/** "isletme" parametresinde tüm seçimin bilerek kaldırıldığını işaretleyen sentinel değer. */
const NONE_SENTINEL = 'none';

/**
 * Filtre linki üretir: seçim tüm işletmeleri kapsıyorsa parametreyi tamamen kaldırır
 * (varsayılan "tümü" durumu). Seçim bilerek sıfıra indirilmişse ("son pil'i de kaldır")
 * `isletme` parametresini olmayan bir durumla karıştırmamak için NONE_SENTINEL yazılır —
 * bu sayede sunucu tarafı "hiç parametre yok → tümü" ile "açıkça sıfır → hiçbiri" ayrımını yapabilir.
 */
function buildFilterHref(ids: string[], allIds: string[], bilgi?: string) {
  const params = new URLSearchParams();
  if (bilgi) params.set('bilgi', bilgi);
  const isAll = allIds.length > 0 && ids.length === allIds.length && allIds.every((id) => ids.includes(id));
  if (ids.length === 0) {
    params.set('isletme', NONE_SENTINEL);
  } else if (!isAll) {
    for (const id of ids) params.append('isletme', id);
  }
  const qs = params.toString();
  return qs ? `/sahip/gosterge-panosu?${qs}` : '/sahip/gosterge-panosu';
}

function pillClass(active: boolean) {
  return [
    'rounded-full border px-3 py-1.5 text-xs font-extrabold transition-colors',
    active
      ? 'border-primary bg-primary/10 text-primary'
      : 'border-border bg-card text-muted hover:border-primary hover:text-primary',
  ].join(' ');
}

export default async function OwnerDashboardPage({ searchParams }: DashboardProps) {
  const { bilgi, isletme } = await searchParams;
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
      // NOT: gerçek tracking pipeline QR taramasını 'qr_scanned' olarak kaydediyor ('qr_scan' değil) — bkz. src/lib/analitik.ts.
      ? (supabase as any).from('analytics_events').select('id', { count: 'exact', head: true }).in('business_id', bizIds).eq('event_name', 'qr_scanned').gte('created_at', since30d)
      : Promise.resolve({ count: 0 }),
    bizIds.length > 0
      ? (supabase as any).from('reviews').select('id', { count: 'exact', head: true }).in('business_id', bizIds).gte('created_at', since7d)
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
        .eq('event_name', 'qr_scanned')
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

  // ── Çoklu işletme seçimi + işletme başına detay bloğu ─────────────────────
  // NOT: bizIds zaten yukarıda getOwnerBusinessIds ile hesaplandı; owner_claims
  // sorgusunu tekrarlamamak için getOwnerBusinessesByIds kullanılır.
  const ownerBusinesses = await getOwnerBusinessesByIds<BizRow>(
    supabase as any,
    bizIds,
    'id, name, slug, category, logo_url, cover_url, is_verified, is_active',
  );
  const allBizIds = ownerBusinesses.map((b) => b.id);

  const requestedIdsRaw = isletme ? (Array.isArray(isletme) ? isletme : [isletme]) : [];
  // Kullanıcı son pil'i de kaldırdığında buildFilterHref `isletme=none` yazar — bu durumda
  // "hiç parametre yok" (→ tümü) ile "açıkça sıfır seçim" (→ hiçbiri) birbirinden ayrılır.
  const isExplicitNone = requestedIdsRaw.length === 1 && requestedIdsRaw[0] === NONE_SENTINEL;
  const requestedIds = requestedIdsRaw.filter((id) => allBizIds.includes(id));
  const selectedIds = isExplicitNone ? [] : requestedIds.length > 0 ? requestedIds : allBizIds;
  const selectedBusinesses = ownerBusinesses.filter((b) => selectedIds.includes(b.id));

  const statsMap = new Map<string, { avg_rating: number | null; reviews_count: number | null }>();
  const favByBiz = new Map<string, TrendCount>();
  const viewsByBiz = new Map<string, TrendCount>();
  const opensByBiz = new Map<string, TrendCount>();
  const qrByBiz = new Map<string, TrendCount>();
  const reviewTrendByBiz = new Map<string, TrendCount>();
  const reviewsByBiz = new Map<string, ReviewRow[]>();
  const planTierByBiz = new Map<string, string>();
  const profileMap = new Map<string, { display_name: string | null; avatar_url: string | null }>();

  if (selectedIds.length > 0) {
    const bucketize = (rows: Array<{ business_id: string; created_at: string }>) => {
      const map = new Map<string, TrendCount>();
      for (const id of selectedIds) map.set(id, { curr: 0, prev: 0 });
      for (const row of rows) {
        const entry = map.get(row.business_id);
        if (!entry) continue;
        if (row.created_at >= since7d) entry.curr += 1;
        else entry.prev += 1;
      }
      return map;
    };

    const [statsRes, favRes, viewsRes, opensRes, qrRes, reviewTrendRes, reviewDetailRes, planResults] = await Promise.all([
      (supabase as any).from('businesses_with_stats').select('id, avg_rating, reviews_count').in('id', selectedIds),
      (supabase as any).from('favorites').select('business_id, created_at').in('business_id', selectedIds).gte('created_at', since14d),
      (supabase as any).from('analytics_events').select('business_id, created_at').in('business_id', selectedIds).eq('event_name', 'business_page_view').gte('created_at', since14d),
      (supabase as any).from('analytics_events').select('business_id, created_at').in('business_id', selectedIds).eq('event_name', 'menu_view').gte('created_at', since14d),
      (supabase as any).from('analytics_events').select('business_id, created_at').in('business_id', selectedIds).eq('event_name', 'qr_scanned').gte('created_at', since14d),
      (supabase as any).from('reviews').select('business_id, created_at').in('business_id', selectedIds).gte('created_at', since14d),
      (supabase as any)
        .from('reviews')
        .select('id, business_id, user_id, rating, content, status, created_at, owner_reply, owner_replied_at')
        .in('business_id', selectedIds)
        .order('created_at', { ascending: false })
        .limit(300),
      Promise.all(
        selectedIds.map((id) =>
          (supabase as any)
            .rpc('get_my_plan_v1', { p_business_id: id })
            .then((r: { data: { plan_tier?: string } | null }) => [id, r?.data?.plan_tier] as const)
            .catch(() => [id, undefined] as const),
        ),
      ),
    ]);

    for (const row of ((statsRes.data ?? []) as Array<{ id: string; avg_rating: number | null; reviews_count: number | null }>)) {
      statsMap.set(row.id, row);
    }
    for (const [id, count] of bucketize(favRes.data ?? [])) favByBiz.set(id, count);
    for (const [id, count] of bucketize(viewsRes.data ?? [])) viewsByBiz.set(id, count);
    for (const [id, count] of bucketize(opensRes.data ?? [])) opensByBiz.set(id, count);
    for (const [id, count] of bucketize(qrRes.data ?? [])) qrByBiz.set(id, count);
    for (const [id, count] of bucketize(reviewTrendRes.data ?? [])) reviewTrendByBiz.set(id, count);

    const detailRows = (reviewDetailRes.data ?? []) as ReviewRow[];
    for (const id of selectedIds) reviewsByBiz.set(id, []);
    for (const row of detailRows) {
      reviewsByBiz.get(row.business_id)?.push(row);
    }

    for (const [id, tier] of (planResults as Array<readonly [string, string | undefined]>)) {
      if (tier) planTierByBiz.set(id, tier);
    }

    const reviewerIds = Array.from(new Set(detailRows.map((r) => r.user_id).filter((id): id is string => Boolean(id))));
    if (reviewerIds.length > 0) {
      const { data: profiles } = await (supabase as any)
        .from('user_profiles').select('user_id, display_name, avatar_url').in('user_id', reviewerIds);
      for (const p of ((profiles ?? []) as Array<{ user_id: string; display_name: string | null; avatar_url: string | null }>)) {
        profileMap.set(p.user_id, { display_name: p.display_name, avatar_url: p.avatar_url });
      }
    }
  }

  const QUICK_ACTIONS = [
    { href: '/sahip/menuler', title: 'Menü Düzenle', subtitle: 'Ürün ve kategorileri güncelle', icon: <MenuIcon /> },
    { href: '/sahip/isletmeler', title: 'İşletme Bilgileri', subtitle: 'Profil ve iletişim bilgilerini düzenle', icon: <BuildingIcon /> },
    { href: '/sahip/pazarlama/kampanyalar', title: 'Kampanya Oluştur', subtitle: 'Yeni bir pazarlama kampanyası başlat', icon: <CampaignIcon /> },
    { href: '/sahip/karekod', title: 'QR Kodu İndir', subtitle: 'QR Stüdyosu ile kod tasarla', icon: <QrIcon /> },
    { href: '/sahip/analitik', title: 'İstatistikleri Gör', subtitle: 'Detaylı performans analizini incele', icon: <ChartIcon /> },
  ];

  return (
    <div className="flex flex-col">
      <PanelSayfaBasligi
        eyebrow="Sahip"
        title="Genel Bakış"
        description="İşletmelerinizin özet durumu ve performans metrikleri"
      />
      <PanelIcerikYuzeyi className="pt-6">
        <div className="flex flex-col gap-6">
          {/* ── Onay bekleniyor banner ── */}
          {(hasPendingClaim || bilgi === 'talep_alindi' || bilgi === 'talep_bekliyor') && (
            <div className="rounded-2xl border border-amber-200 bg-amber-50 px-5 py-4">
              <div className="flex items-start gap-3">
                <Clock size={20} className="shrink-0 text-amber-700" aria-hidden="true" />
                <div>
                  <p className="font-black text-amber-900">
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
              <p className="font-black text-textStrong">İşletme bulunamadı</p>
              <p className="mt-1 text-sm text-muted">
                Henüz bir işletme eklemediniz veya sahiplenme talebiniz yok.
              </p>
              <Link
                href="/sahiplen/ara"
                className="mt-3 inline-flex rounded-xl border border-primary bg-primary/8 px-4 py-2 text-sm font-extrabold text-primary hover:bg-primary/15"
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
                <p className="text-2xl font-black text-primary">{qrScanCount30d.toLocaleString('tr-TR')}</p>
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
                <p className="text-2xl font-black text-blue-600">{viewCount7d.toLocaleString('tr-TR')}</p>
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
          <PanelBolumKarti title="Hızlı İşlemler">
            <div className="grid grid-cols-2 gap-3 sm:grid-cols-3 lg:grid-cols-5">
              {QUICK_ACTIONS.map((a) => (
                <Link
                  key={a.href}
                  href={a.href}
                  className="group flex flex-col gap-2 rounded-xl border border-border p-4 transition-colors hover:border-primary"
                >
                  <span className="flex h-9 w-9 items-center justify-center rounded-lg bg-primary/8 text-primary">
                    {a.icon}
                  </span>
                  <span className="text-sm font-extrabold text-textStrong group-hover:text-primary">{a.title}</span>
                  <span className="text-xs leading-snug text-muted">{a.subtitle}</span>
                </Link>
              ))}
            </div>
          </PanelBolumKarti>

          {/* ── İşletme başına detay: seçici + tekrarlayan blok ── */}
          {ownerBusinesses.length > 0 && (
            <div className="flex flex-col gap-4">
              <h2 className="text-[15px] font-black text-textStrong">İşletme Detayları</h2>

              {ownerBusinesses.length > 1 && (
                <div className="flex flex-wrap items-center gap-2">
                  <Link
                    href={buildFilterHref(allBizIds, allBizIds, bilgi)}
                    className={pillClass(selectedIds.length === allBizIds.length)}
                  >
                    Tümü
                  </Link>
                  {ownerBusinesses.map((b) => {
                    const isSelected = selectedIds.includes(b.id);
                    const nextIds = isSelected
                      ? selectedIds.filter((id) => id !== b.id)
                      : [...selectedIds, b.id];
                    return (
                      <Link
                        key={b.id}
                        href={buildFilterHref(nextIds, allBizIds, bilgi)}
                        className={pillClass(isSelected)}
                      >
                        {b.name}
                      </Link>
                    );
                  })}
                </div>
              )}

              {selectedBusinesses.length === 0 ? (
                <p className="text-sm text-muted">Görüntülemek için en az bir işletme seçin.</p>
              ) : (
                <div className="flex flex-col gap-6">
                  {selectedBusinesses.map((b) => {
                    const stats = statsMap.get(b.id) ?? { avg_rating: null, reviews_count: null };
                    const favTrend = favByBiz.get(b.id) ?? { curr: 0, prev: 0 };
                    const viewsTrend = viewsByBiz.get(b.id) ?? { curr: 0, prev: 0 };
                    const opensTrend = opensByBiz.get(b.id) ?? { curr: 0, prev: 0 };
                    const qrTrend = qrByBiz.get(b.id) ?? { curr: 0, prev: 0 };
                    const reviewTrend = reviewTrendByBiz.get(b.id) ?? { curr: 0, prev: 0 };
                    const bizReviews = reviewsByBiz.get(b.id) ?? [];
                    const planTier = planTierByBiz.get(b.id);

                    return (
                      <div key={b.id} className="flex flex-col gap-4 rounded-2xl border border-border bg-bg/60 p-4 sm:p-6">
                        <BusinessPreviewCard
                          business={b}
                          avgRating={stats.avg_rating}
                          reviewsCount={stats.reviews_count}
                        />

                        {planTier === 'free' && <PremiumBanner />}

                        <div className="grid grid-cols-2 gap-3 sm:grid-cols-5">
                          <MetricCard
                            title="Görüntülenme"
                            value={viewsTrend.curr}
                            trend={{ value: pctChange(viewsTrend.curr, viewsTrend.prev), label: '7 gün' }}
                            icon={<EyeIcon />}
                          />
                          <MetricCard
                            title="Favori Eklenme"
                            value={favTrend.curr}
                            trend={{ value: pctChange(favTrend.curr, favTrend.prev), label: '7 gün' }}
                            icon={<HeartIcon />}
                          />
                          <MetricCard
                            title="Yorum"
                            value={reviewTrend.curr}
                            trend={{ value: pctChange(reviewTrend.curr, reviewTrend.prev), label: '7 gün' }}
                            icon={<StarIcon />}
                          />
                          <MetricCard
                            title="QR Tarama"
                            value={qrTrend.curr}
                            trend={{ value: pctChange(qrTrend.curr, qrTrend.prev), label: '7 gün' }}
                            icon={<QrIcon />}
                          />
                          <MetricCard
                            title="Menü Açılma"
                            value={opensTrend.curr}
                            trend={{ value: pctChange(opensTrend.curr, opensTrend.prev), label: '7 gün' }}
                            icon={<MenuIcon />}
                          />
                        </div>

                        <div className="grid gap-4 lg:grid-cols-2">
                          <PanelBolumKarti title="Son Aktiviteler" noPadding>
                            {bizReviews.length === 0 ? (
                              <p className="px-5 py-8 text-center text-sm text-muted">Henüz aktivite yok</p>
                            ) : (
                              <ul className="divide-y divide-border">
                                {bizReviews.slice(0, 4).map((r) => (
                                  <li key={r.id} className="flex items-start gap-3 px-5 py-3">
                                    <span className="flex h-8 w-8 shrink-0 items-center justify-center rounded-full bg-primary/8 text-primary">
                                      <StarIcon size={14} />
                                    </span>
                                    <div className="min-w-0 flex-1">
                                      <p className="text-xs font-extrabold text-textStrong">Yeni yorum aldı</p>
                                      <p className="truncate text-xs text-muted">
                                        {r.content
                                          ? `"${r.content.slice(0, 50)}${r.content.length > 50 ? '…' : ''}"`
                                          : 'Yorum geldi'}
                                      </p>
                                    </div>
                                    <span className="shrink-0 text-[11px] text-muted">{timeAgo(r.created_at)}</span>
                                  </li>
                                ))}
                              </ul>
                            )}
                          </PanelBolumKarti>

                          <PanelBolumKarti
                            title="Yorumlar"
                            actions={
                              <Link href="/sahip/yorumlar" className="text-xs font-extrabold text-primary hover:underline">
                                Tümünü Gör
                              </Link>
                            }
                            noPadding
                          >
                            {bizReviews.length === 0 ? (
                              <p className="px-5 py-8 text-center text-sm text-muted">Henüz yorum yok</p>
                            ) : (
                              <ul className="divide-y divide-border">
                                {bizReviews.slice(0, 3).map((r) => {
                                  const profile = r.user_id ? profileMap.get(r.user_id) : undefined;
                                  return (
                                    <li key={r.id} className="px-5 py-3">
                                      <div className="flex items-start gap-3">
                                        <ReviewerAvatar
                                          avatarUrl={profile?.avatar_url ?? null}
                                          displayName={profile?.display_name ?? null}
                                        />
                                        <div className="min-w-0 flex-1">
                                          <div className="flex flex-wrap items-center gap-2">
                                            <StarRatingRow rating={r.rating} />
                                            <span className="text-xs font-bold text-textStrong">
                                              {profile?.display_name ?? 'Anonim'}
                                            </span>
                                            {!r.owner_reply && (
                                              <span className="rounded-full bg-primary/10 px-2 py-0.5 text-[10px] font-extrabold text-primary">
                                                Yeni
                                              </span>
                                            )}
                                          </div>
                                          {r.content && (
                                            <p className="mt-1 truncate text-xs text-muted">{r.content}</p>
                                          )}
                                        </div>
                                        <Link
                                          href="/sahip/yorumlar"
                                          className="shrink-0 text-[11px] font-extrabold text-primary hover:underline"
                                        >
                                          Yanıtla
                                        </Link>
                                      </div>
                                    </li>
                                  );
                                })}
                              </ul>
                            )}
                          </PanelBolumKarti>
                        </div>
                      </div>
                    );
                  })}
                </div>
              )}
            </div>
          )}
        </div>
      </PanelIcerikYuzeyi>
    </div>
  );
}

function BusinessPreviewCard({
  business,
  avgRating,
  reviewsCount,
}: {
  business: BizRow;
  avgRating: number | null;
  reviewsCount: number | null;
}) {
  const coverUrl = buildMenuImageUrl(business.cover_url, { width: 900, quality: 80 });
  const logoUrl = business.logo_url ? buildMenuImageUrl(business.logo_url, { width: 160, quality: 84 }) : null;

  return (
    <div className="overflow-hidden rounded-2xl border border-border bg-card">
      <div className="relative min-h-[130px] bg-textStrong/90">
        {coverUrl && (
          // eslint-disable-next-line @next/next/no-img-element
          <img src={coverUrl} alt="" className="absolute inset-0 h-full w-full object-cover" />
        )}
        <div className="absolute inset-0 bg-gradient-to-t from-textStrong/85 via-textStrong/15 to-transparent" />
        <div className="absolute inset-x-0 bottom-0 flex items-end gap-3 p-4">
          <div className="flex h-14 w-14 shrink-0 items-center justify-center overflow-hidden rounded-2xl border border-white/30 bg-card text-xl font-black text-textStrong shadow-yd2">
            {logoUrl ? (
              // eslint-disable-next-line @next/next/no-img-element
              <img src={logoUrl} alt={business.name} className="h-full w-full object-cover" />
            ) : (
              business.name.charAt(0).toUpperCase()
            )}
          </div>
          <div className="min-w-0 pb-0.5">
            <div className="flex flex-wrap items-center gap-1.5">
              <p className="truncate text-base font-black text-white">{business.name}</p>
              {business.is_verified && (
                <span className="shrink-0 rounded-full bg-primary px-2 py-0.5 text-[10px] font-extrabold text-white">
                  Onaylı
                </span>
              )}
            </div>
            <p className="truncate text-xs font-bold text-white/80">
              {business.category ?? 'Kategori yok'}
              {avgRating != null && ` · ★ ${avgRating.toFixed(1)} (${reviewsCount ?? 0})`}
            </p>
          </div>
        </div>
      </div>
      <div className="flex flex-wrap items-center justify-between gap-3 px-4 py-3">
        <span
          className={`rounded-full px-2.5 py-0.5 text-[11px] font-extrabold ${
            business.is_active ? 'bg-green-50 text-green-700' : 'bg-zinc-100 text-zinc-500'
          }`}
        >
          {business.is_active ? 'Yayında' : 'Pasif'}
        </span>
        <div className="flex items-center gap-2">
          <Link
            href={`/sahip/isletmeler/${business.id}`}
            className="rounded-xl border border-border bg-card px-3 py-1.5 text-xs font-extrabold text-textStrong hover:border-primary hover:text-primary"
          >
            Sayfayı Düzenle
          </Link>
          {business.slug && (
            <a
              href={`/isletme/${business.slug}`}
              target="_blank"
              rel="noreferrer"
              className="btn-primary rounded-xl px-3 py-1.5 text-xs font-extrabold"
            >
              Sayfayı Görüntüle
            </a>
          )}
        </div>
      </div>
    </div>
  );
}

function PremiumBanner() {
  return (
    <div className="flex flex-wrap items-center justify-between gap-3 rounded-2xl border border-primary/25 bg-primary/5 px-5 py-4">
      <div>
        <p className="text-sm font-black text-textStrong">Premium&apos;a Geçin</p>
        <p className="mt-0.5 text-xs text-muted">
          Daha fazla müşteriye ulaşın, gelişmiş analiz ve pazarlama araçlarının kilidini açın.
        </p>
      </div>
      <Link href="/sahip/ayarlar/plan" className="btn-primary inline-flex shrink-0 items-center rounded-xl px-4 py-2 text-xs font-extrabold">
        Planları İncele
      </Link>
    </div>
  );
}

function ReviewerAvatar({ avatarUrl, displayName }: { avatarUrl: string | null; displayName: string | null }) {
  const initial = (displayName ?? 'K').charAt(0).toUpperCase();
  if (avatarUrl) {
    return (
      // eslint-disable-next-line @next/next/no-img-element
      <img
        src={avatarUrl}
        alt={displayName ?? 'Kullanıcı'}
        className="h-9 w-9 shrink-0 rounded-full border border-border object-cover"
      />
    );
  }
  return (
    <div className="flex h-9 w-9 shrink-0 items-center justify-center rounded-full bg-bg text-[13px] font-black text-textStrong">
      {initial}
    </div>
  );
}

function StarRatingRow({ rating }: { rating: number }) {
  return (
    <div className="flex items-center gap-0.5">
      {[1, 2, 3, 4, 5].map((n) => (
        <svg
          key={n}
          width="12"
          height="12"
          viewBox="0 0 24 24"
          fill={n <= rating ? 'currentColor' : 'none'}
          stroke="currentColor"
          strokeWidth="2"
          className={n <= rating ? 'text-amber-400' : 'text-zinc-300'}
        >
          <polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2" />
        </svg>
      ))}
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

function StarIcon({ size = 20 }: { size?: number }) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2" />
    </svg>
  );
}

function EyeIcon() {
  return (
    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M1 12s4-7 11-7 11 7 11 7-4 7-11 7-11-7-11-7z" />
      <circle cx="12" cy="12" r="3" />
    </svg>
  );
}

function HeartIcon() {
  return (
    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M20.8 4.6a5.5 5.5 0 0 0-7.8 0L12 5.7l-1-1.1a5.5 5.5 0 0 0-7.8 7.8l1 1L12 21l7.8-7.8 1-1a5.5 5.5 0 0 0 0-7.6z" />
    </svg>
  );
}

function ChartIcon() {
  return (
    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <line x1="12" y1="20" x2="12" y2="10" />
      <line x1="18" y1="20" x2="18" y2="4" />
      <line x1="6" y1="20" x2="6" y2="16" />
    </svg>
  );
}

function CampaignIcon() {
  return (
    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M3 11l18-6v14l-18-6v-2z" />
      <path d="M7 15v4a2 2 0 0 0 2 2h1v-6" />
    </svg>
  );
}
