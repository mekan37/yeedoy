import type { Metadata } from 'next';
import Link from 'next/link';
import Image from 'next/image';
import { Clock, Megaphone, BarChart3, BadgeCheck } from 'lucide-react';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { PanelSayfaBasligi } from '@/src/ui/yerlesim/panel-page-header';
import { PanelIcerikYuzeyi, PanelBolumKarti } from '@/src/ui/yerlesim/panel-section-card';
import { MetricCard } from '@/src/ui/bilesenler/olcum-karti';
import { getOwnerBusinessIds } from '@/src/lib/veri/owner/sahip-isletmeleri';
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

function timeAgo(iso: string) {
  const diff = Date.now() - new Date(iso).getTime();
  const m = Math.floor(diff / 60000);
  if (m < 60) return `${m} dk önce`;
  const h = Math.floor(m / 60);
  if (h < 24) return `${h} saat önce`;
  return `${Math.floor(h / 24)} gün önce`;
}

type PrimaryBusiness = {
  id: string;
  name: string;
  category: string | null;
  logo_url: string | null;
  cover_url: string | null;
  is_verified: boolean | null;
  slug: string | null;
  is_active: boolean | null;
};

type RecentReviewRow = {
  id: string;
  rating: number;
  content: string | null;
  created_at: string;
  owner_reply: string | null;
  user_id: string | null;
  user_profiles?: { display_name: string; avatar_url: string | null } | null;
};

type DashboardProps = { searchParams: Promise<{ bilgi?: string }> };

export default async function OwnerDashboardPage({ searchParams }: DashboardProps) {
  const { bilgi } = await searchParams;
  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();

  const bizIds = await getOwnerBusinessIds(supabase as any, user!.id);

  const { data: profile } = await (supabase as any)
    .from('user_profiles')
    .select('display_name')
    .eq('user_id', user!.id)
    .maybeSingle();
  const displayName: string = profile?.display_name ?? user!.email?.split('@')[0] ?? 'Kullanıcı';
  const firstName = displayName.split(' ')[0] ?? displayName;

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
  const since14d = new Date(Date.now() - 14 * 24 * 60 * 60 * 1000).toISOString();
  const since30d = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString();

  const [
    menusRes, qrScans30dRes, qrScans7dRes, reviewsRes, reviewsPrevRes,
    favCurrRes, favPrevRes, views7d, views30d, bizListRes,
  ] = await Promise.all([
    bizIds.length > 0
      ? (supabase as any).from('menus').select('id', { count: 'exact', head: true }).in('business_id', bizIds) as Promise<{ count: number | null }>
      : Promise.resolve({ count: 0 }),
    bizIds.length > 0
      ? (supabase as any).from('analytics_events').select('id', { count: 'exact', head: true }).in('business_id', bizIds).eq('event_name', 'qr_scan').gte('created_at', since30d)
      : Promise.resolve({ count: 0 }),
    bizIds.length > 0
      ? (supabase as any).from('analytics_events').select('id', { count: 'exact', head: true }).in('business_id', bizIds).eq('event_name', 'qr_scan').gte('created_at', since7d)
      : Promise.resolve({ count: 0 }),
    bizIds.length > 0
      ? (supabase as any).from('business_reviews').select('id', { count: 'exact', head: true }).in('business_id', bizIds).gte('created_at', since7d)
      : Promise.resolve({ count: 0 }),
    bizIds.length > 0
      ? (supabase as any).from('business_reviews').select('id', { count: 'exact', head: true }).in('business_id', bizIds).gte('created_at', since14d).lt('created_at', since7d)
      : Promise.resolve({ count: 0 }),
    bizIds.length > 0
      ? (supabase as any).from('favorites').select('id', { count: 'exact', head: true }).in('business_id', bizIds).gte('created_at', since7d)
      : Promise.resolve({ count: 0 }),
    bizIds.length > 0
      ? (supabase as any).from('favorites').select('id', { count: 'exact', head: true }).in('business_id', bizIds).gte('created_at', since14d).lt('created_at', since7d)
      : Promise.resolve({ count: 0 }),
    bizIds.length > 0
      ? (supabase as any).from('analytics_events').select('id', { count: 'exact', head: true }).in('business_id', bizIds).eq('event_name', 'menu_view').gte('created_at', since7d)
      : Promise.resolve({ count: 0 }),
    bizIds.length > 0
      ? (supabase as any).from('analytics_events').select('id', { count: 'exact', head: true }).in('business_id', bizIds).eq('event_name', 'menu_view').gte('created_at', since30d)
      : Promise.resolve({ count: 0 }),
    // İlk işletme (alfabetik) — görsel bölüm için
    bizIds.length > 0
      ? (supabase as any)
          .from('businesses')
          .select('id, name, category, logo_url, cover_url, is_verified, slug, is_active')
          .in('id', bizIds)
          .order('name', { ascending: true }) as Promise<{ data: PrimaryBusiness[] | null }>
      : Promise.resolve({ data: [] as PrimaryBusiness[] }),
  ]);

  const businessCount = bizIds.length;
  const menuCount = menusRes.count ?? 0;
  const qrScanCount30d = qrScans30dRes.count ?? 0;
  const qrScanCount7d = qrScans7dRes.count ?? 0;
  const reviewCount7d = reviewsRes.count ?? 0;
  const reviewCount7dPrev = reviewsPrevRes.count ?? 0;
  const favCount7d = favCurrRes.count ?? 0;
  const favCount7dPrev = favPrevRes.count ?? 0;
  const viewCount7d = views7d.count ?? 0;
  const viewCount30d = views30d.count ?? 0;
  const engagementCount7d = qrScanCount7d + viewCount7d;

  function pctChange(curr: number, prev: number): number | null {
    if (prev === 0) return curr > 0 ? 100 : null;
    return Math.round(((curr - prev) / prev) * 100);
  }
  const reviewPct = pctChange(reviewCount7d, reviewCount7dPrev);
  const favPct = pctChange(favCount7d, favCount7dPrev);

  // Çoklu işletmeli sahipler için görsel bölüm ilk işletmeye (alfabetik) ait gösterilir.
  const primaryBiz: PrimaryBusiness | null = (bizListRes.data ?? [])[0] ?? null;

  const [bizStatsRes, recentReviewsRes] = await Promise.all([
    primaryBiz
      ? (supabase as any).from('businesses_with_stats').select('avg_rating, reviews_count').eq('id', primaryBiz.id).maybeSingle()
      : Promise.resolve({ data: null }),
    primaryBiz
      ? (supabase as any)
          .from('reviews')
          .select('id, rating, content, created_at, owner_reply, user_id')
          .eq('business_id', primaryBiz.id)
          .eq('status', 'approved')
          .order('created_at', { ascending: false })
          .limit(3) as Promise<{ data: RecentReviewRow[] | null }>
      : Promise.resolve({ data: [] as RecentReviewRow[] }),
  ]);

  const avgRating: number | null = bizStatsRes?.data?.avg_rating ?? null;
  const totalReviews: number = bizStatsRes?.data?.reviews_count ?? 0;

  const recentReviews: RecentReviewRow[] = recentReviewsRes?.data ?? [];
  if (recentReviews.length > 0) {
    const reviewUserIds = [...new Set(recentReviews.map((r) => r.user_id).filter(Boolean))] as string[];
    if (reviewUserIds.length > 0) {
      const { data: reviewerProfiles } = await (supabase as any)
        .from('user_profiles')
        .select('user_id, display_name, avatar_url')
        .in('user_id', reviewUserIds);
      const profileMap: Record<string, { display_name: string; avatar_url: string | null }> = {};
      for (const p of reviewerProfiles ?? []) profileMap[p.user_id] = p;
      for (const r of recentReviews) {
        if (r.user_id) r.user_profiles = profileMap[r.user_id] ?? null;
      }
    }
  }

  const coverUrl = primaryBiz ? buildMenuImageUrl(primaryBiz.cover_url, { width: 800, quality: 80 }) : null;
  const logoUrl = primaryBiz?.logo_url ? buildMenuImageUrl(primaryBiz.logo_url, { width: 80, quality: 80 }) : null;

  // Daily QR scan counts for last 14 days sparkline
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

  const QUICK_ACTIONS = [
    { href: '/sahip/menuler', icon: <MenuIcon />, title: 'Menü Düzenle', sub: 'Menünüzü güncelleyin' },
    { href: '/sahip/isletmeler', icon: <BuildingIcon />, title: 'İşletme Bilgileri', sub: 'Bilgilerinizi düzenleyin' },
    { href: '/sahip/pazarlama/kampanyalar', icon: <Megaphone size={18} />, title: 'Kampanya Oluştur', sub: 'Yeni kampanya ekleyin' },
    { href: '/sahip/karekod', icon: <QrIcon />, title: 'QR Kodu İndir', sub: 'QR menünüzü indirin' },
    { href: '/sahip/analitik', icon: <BarChart3 size={18} />, title: 'İstatistikleri Gör', sub: 'Detaylı raporları inceleyin' },
  ];

  return (
    <div className="flex flex-col">
      <PanelSayfaBasligi
        eyebrow="Owner"
        title={`Merhaba ${firstName}! 👋`}
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
          <div className="grid grid-cols-2 gap-4 sm:grid-cols-3 lg:grid-cols-6">
            <MetricCard title="İşletmeler" value={businessCount} icon={<BuildingIcon />} />
            <MetricCard title="Menüler" value={menuCount} icon={<MenuIcon />} />
            <MetricCard
              title="Görüntülenme"
              value={engagementCount7d}
              subtitle="Son 7 gün"
              icon={<EyeStatIcon />}
            />
            <MetricCard
              title="Favori Eklenme"
              value={favCount7d}
              subtitle="Önceki 7 güne göre"
              icon={<HeartStatIcon />}
              trend={favPct !== null ? { value: favPct } : undefined}
            />
            <MetricCard
              title="Son 7 Gün Yorum"
              value={reviewCount7d}
              subtitle="Önceki 7 güne göre"
              icon={<StarIcon />}
              trend={reviewPct !== null ? { value: reviewPct } : undefined}
            />
            <MetricCard title="Son 30 Gün QR Tarama" value={qrScanCount30d} icon={<QrIcon />} />
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

          {/* ── Görsel bölüm: seçili/ilk işletme önizlemesi + son aktiviteler ── */}
          {primaryBiz && (
            <div className="grid gap-4 lg:grid-cols-[1fr_340px]">
              {/* Son Aktiviteler (son 3 yorum önizlemesi + yanıtla linki) */}
              <PanelBolumKarti
                title="Son Aktiviteler"
                actions={
                  <Link href="/sahip/yorumlar" className="text-xs font-[800] text-primary hover:underline">
                    Tümünü Gör →
                  </Link>
                }
              >
                {recentReviews.length === 0 ? (
                  <p className="text-sm text-muted">Henüz yorum yok</p>
                ) : (
                  <div className="divide-y divide-border">
                    {recentReviews.map((r) => (
                      <div key={r.id} className="py-3 first:pt-0 last:pb-0">
                        <div className="mb-1.5 flex items-center gap-3">
                          <ReviewerAvatar profile={r.user_profiles ?? null} />
                          <div className="min-w-0 flex-1">
                            <p className="truncate text-sm font-[800] text-textStrong">
                              {r.user_profiles?.display_name ?? 'Kullanıcı'}
                            </p>
                            <div className="flex items-center gap-2">
                              <ReviewStars rating={r.rating} />
                              <span className="text-[11px] font-[600] text-muted">{timeAgo(r.created_at)}</span>
                              {!r.owner_reply && (
                                <span className="rounded-full bg-primary/10 px-2 py-0.5 text-[10px] font-[800] text-primary">Yeni</span>
                              )}
                            </div>
                          </div>
                          <Link
                            href="/sahip/yorumlar"
                            className="shrink-0 rounded-lg border border-border px-2.5 py-1 text-[11px] font-[800] text-textStrong hover:bg-bg"
                          >
                            ↩ Yanıtla
                          </Link>
                        </div>
                        {r.content && (
                          <p className="line-clamp-2 text-sm leading-relaxed text-muted">{r.content}</p>
                        )}
                      </div>
                    ))}
                  </div>
                )}
                <Link
                  href="/sahip/etkinlik"
                  className="mt-3 flex items-center gap-1 text-xs font-[800] text-primary hover:underline"
                >
                  Tüm Aktiviteler →
                </Link>
              </PanelBolumKarti>

              {/* İşletme önizlemesi (cover/logo/yıldız puanı) */}
              <PanelBolumKarti noPadding className="overflow-hidden">
                <div className="relative h-[160px] bg-gradient-to-br from-primary/80 to-primary">
                  {coverUrl && (
                    <Image src={coverUrl} alt={primaryBiz.name} fill sizes="340px" className="object-cover" />
                  )}
                  {logoUrl && (
                    <div className="absolute bottom-0 left-1/2 -translate-x-1/2 translate-y-1/2">
                      <Image
                        src={logoUrl}
                        alt={primaryBiz.name}
                        width={60}
                        height={60}
                        className="rounded-full border-4 border-card object-cover shadow-md"
                      />
                    </div>
                  )}
                </div>

                <div className="px-5 pb-5 pt-10 text-center">
                  <div className="flex items-center justify-center gap-1.5">
                    <p className="text-[15px] font-[900] text-textStrong">{primaryBiz.name}</p>
                    {primaryBiz.is_verified && (
                      <BadgeCheck size={16} className="text-blue-600" aria-hidden="true" />
                    )}
                  </div>
                  {primaryBiz.category && (
                    <p className="mt-0.5 text-xs font-[600] text-muted">{primaryBiz.category}</p>
                  )}
                  <div className="mt-2 flex items-center justify-center gap-3 text-xs text-muted">
                    {avgRating != null && (
                      <span className="flex items-center gap-1 font-[800] text-textStrong">
                        <span className="text-amber-500">★</span>
                        {avgRating.toFixed(1)}
                        <span className="font-[600] text-muted">({totalReviews})</span>
                      </span>
                    )}
                    <span className="h-3 w-px bg-border" />
                    <span className={`font-[800] ${primaryBiz.is_active ? 'text-green-600' : 'text-muted'}`}>
                      {primaryBiz.is_active ? 'Açık' : 'Kapalı'}
                    </span>
                  </div>
                  {businessCount > 1 && (
                    <p className="mt-2 text-[11px] text-muted">
                      +{businessCount - 1} işletme daha ·{' '}
                      <Link href="/sahip/isletmeler" className="font-[700] text-primary hover:underline">
                        Tümünü gör
                      </Link>
                    </p>
                  )}
                  <div className="mt-4 flex gap-2">
                    <Link
                      href={`/sahip/isletmeler/${primaryBiz.id}`}
                      className="flex-1 rounded-xl border border-border py-2 text-xs font-[800] text-textStrong transition-colors hover:bg-bg"
                    >
                      Sayfayı Düzenle
                    </Link>
                    {primaryBiz.slug && (
                      <Link
                        href={`/isletme/${primaryBiz.slug}`}
                        target="_blank"
                        className="btn-primary flex-1 rounded-xl py-2 text-xs font-[900] text-white transition-opacity hover:opacity-90"
                      >
                        Sayfayı Görüntüle
                      </Link>
                    )}
                  </div>
                </div>
              </PanelBolumKarti>
            </div>
          )}

          {/* Quick actions */}
          <PanelBolumKarti title="Hızlı İşlemler">
            <div className="grid grid-cols-2 gap-3 sm:grid-cols-3 lg:grid-cols-5">
              {QUICK_ACTIONS.map((qa) => (
                <Link
                  key={qa.href}
                  href={qa.href}
                  className="flex flex-col items-center gap-2 rounded-2xl border border-border bg-card p-4 text-center shadow-sm transition-all hover:-translate-y-0.5 hover:shadow-md"
                >
                  <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-primary/10 text-primary">
                    {qa.icon}
                  </div>
                  <p className="text-xs font-[800] text-textStrong">{qa.title}</p>
                  <p className="text-[10px] font-[600] leading-tight text-muted">{qa.sub}</p>
                </Link>
              ))}
            </div>
          </PanelBolumKarti>

          {/* ── Premium banner ── */}
          {primaryBiz && (
            <div className="flex flex-col items-start justify-between gap-4 rounded-2xl border border-primary/20 bg-primary/5 p-5 sm:flex-row sm:items-center">
              <div className="flex items-center gap-4">
                <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-primary/10 text-[20px]">
                  🎁
                </div>
                <div>
                  <p className="text-sm font-[900] text-textStrong">Premium&apos;a Geçin</p>
                  <p className="text-xs font-[600] text-muted">Daha fazla müşteriye ulaşın, öne çıkan işletmeler arasında yer alın.</p>
                </div>
              </div>
              <button
                type="button"
                className="btn-primary shrink-0 flex items-center gap-2 rounded-xl px-4 py-2 text-sm font-[900] text-white transition-opacity hover:opacity-90"
              >
                Premium&apos;a Geç <span>›</span>
              </button>
            </div>
          )}
        </div>
      </PanelIcerikYuzeyi>
    </div>
  );
}

function ReviewerAvatar({ profile }: { profile: { display_name: string; avatar_url: string | null } | null }) {
  const name = profile?.display_name ?? 'K';
  if (profile?.avatar_url) {
    // eslint-disable-next-line @next/next/no-img-element
    return <img src={profile.avatar_url} alt={name} className="h-9 w-9 shrink-0 rounded-full border border-border object-cover" />;
  }
  return (
    <div className="flex h-9 w-9 shrink-0 items-center justify-center rounded-full bg-bg text-[13px] font-[900] text-textStrong">
      {name.charAt(0).toUpperCase()}
    </div>
  );
}

function ReviewStars({ rating }: { rating: number }) {
  return (
    <div className="flex items-center gap-0.5 text-amber-500">
      {[1, 2, 3, 4, 5].map((s) => (
        <svg key={s} width="11" height="11" viewBox="0 0 24 24" fill={s <= rating ? 'currentColor' : 'none'} stroke="currentColor" strokeWidth="2">
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

function StarIcon() {
  return (
    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2" />
    </svg>
  );
}

function EyeStatIcon() {
  return (
    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z" />
      <circle cx="12" cy="12" r="3" />
    </svg>
  );
}

function HeartStatIcon() {
  return (
    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z" />
    </svg>
  );
}
