import type { Metadata } from 'next';
import Link from 'next/link';
import Image from 'next/image';
import { createSupabaseServerClient } from '@/src/lib/supabaseServer';
import { ViewsChart, type ViewsDataPoint } from '@/src/ui/owner/views-chart';
import { buildMenuImageUrl } from '@/src/lib/medya-adresi';

export const metadata: Metadata = {
  title: 'Genel Bakış | Owner Panel',
  robots: { index: false, follow: false },
};

const DAYS = 7;

type ReviewRow = {
  id: string;
  rating: number;
  content: string | null;
  created_at: string;
  owner_reply: string | null;
  user_profiles?: { display_name: string; avatar_url: string | null } | null;
  user_id: string | null;
};

type AnalyticsDaily = { day: string; qr_scans: number; menu_opens: number; menu_views: number };

function fmtDate(iso: string) {
  return new Date(iso).toLocaleDateString('tr-TR', { day: 'numeric', month: 'short' });
}

function timeAgo(iso: string) {
  const diff = Date.now() - new Date(iso).getTime();
  const m = Math.floor(diff / 60000);
  if (m < 60) return `${m} dk önce`;
  const h = Math.floor(m / 60);
  if (h < 24) return `${h} saat önce`;
  return `${Math.floor(h / 24)} gün önce`;
}

export default async function OwnerDashboardPage() {
  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return null;

  // Get primary business
  const { data: claimData } = await (supabase as any)
    .from('owner_claims')
    .select('business_id, businesses(id, name, category, logo_url, cover_url, is_verified, slug, is_active)')
    .eq('user_id', user.id)
    .eq('status', 'approved')
    .limit(1)
    .maybeSingle();

  const biz = claimData?.businesses ?? null;

  // User display name
  const { data: profile } = await (supabase as any)
    .from('user_profiles')
    .select('display_name')
    .eq('user_id', user.id)
    .maybeSingle();
  const displayName: string = profile?.display_name ?? user.email?.split('@')[0] ?? 'Kullanıcı';
  const firstName = displayName.split(' ')[0] ?? displayName;

  if (!biz) {
    return (
      <div className="flex flex-col items-center justify-center min-h-[60vh] gap-4 p-8">
        <p className="text-lg font-[800] text-[#1a1a2e]">Henüz onaylı bir işletmeniz yok</p>
        <Link
          href="/owner/businesses/new"
          className="rounded-xl px-5 py-2.5 text-sm font-[800] text-white"
          style={{ background: 'linear-gradient(135deg, #7f1d1d, #dc2626)' }}
        >
          İşletme Ekle
        </Link>
      </div>
    );
  }

  const businessId: string = biz.id;

  // Parallel fetches
  const since7 = new Date(Date.now() - DAYS * 86400000).toISOString();
  const since14 = new Date(Date.now() - DAYS * 2 * 86400000).toISOString();

  const [
    analyticsRes,
    reviewsRes,
    favCurrRes,
    favPrevRes,
    revCurrRes,
    revPrevRes,
    statsRes,
  ] = await Promise.all([
    // Analytics daily breakdown
    (supabase as any)
      .rpc('list_owner_analytics_v1', { p_business_id: businessId, p_days: DAYS })
      .catch(() => ({ data: null })),
    // Recent reviews (last 5)
    (supabase as any)
      .from('business_reviews')
      .select('id, rating, content, created_at, owner_reply, user_id')
      .eq('business_id', businessId)
      .eq('status', 'approved')
      .order('created_at', { ascending: false })
      .limit(3) as Promise<{ data: ReviewRow[] | null }>,
    // Favorites this 7 days
    (supabase as any)
      .from('favorites')
      .select('id', { count: 'exact', head: true })
      .eq('business_id', businessId)
      .gte('created_at', since7),
    // Favorites prev 7 days
    (supabase as any)
      .from('favorites')
      .select('id', { count: 'exact', head: true })
      .eq('business_id', businessId)
      .gte('created_at', since14)
      .lt('created_at', since7),
    // Reviews this 7 days
    (supabase as any)
      .from('business_reviews')
      .select('id', { count: 'exact', head: true })
      .eq('business_id', businessId)
      .eq('status', 'approved')
      .gte('created_at', since7),
    // Reviews prev 7 days
    (supabase as any)
      .from('business_reviews')
      .select('id', { count: 'exact', head: true })
      .eq('business_id', businessId)
      .eq('status', 'approved')
      .gte('created_at', since14)
      .lt('created_at', since7),
    // Business stats (avg rating, total reviews)
    (supabase as any)
      .from('businesses_with_stats')
      .select('avg_rating, reviews_count')
      .eq('id', businessId)
      .maybeSingle(),
  ]);

  // Parse analytics
  const analyticsData = analyticsRes?.data as { summary?: { qr_scans: number; menu_opens: number }; daily?: AnalyticsDaily[] } | null;
  const summary = analyticsData?.summary ?? { qr_scans: 0, menu_opens: 0 };
  const dailyRows: AnalyticsDaily[] = analyticsData?.daily ?? [];

  // Chart data: sum qr_scans + menu_opens + menu_views per day
  const chartData: ViewsDataPoint[] = dailyRows.map((d) => ({
    label: fmtDate(d.day),
    value: (d.qr_scans ?? 0) + (d.menu_opens ?? 0) + (d.menu_views ?? 0),
  }));

  // Stats
  const viewsTotal = summary.qr_scans + summary.menu_opens;
  const favCurr = favCurrRes?.count ?? 0;
  const favPrev = favPrevRes?.count ?? 0;
  const revCurr = revCurrRes?.count ?? 0;
  const revPrev = revPrevRes?.count ?? 0;

  function pctChange(curr: number, prev: number) {
    if (prev === 0) return curr > 0 ? 100 : 0;
    return Math.round(((curr - prev) / prev) * 100);
  }

  const favPct = pctChange(favCurr, favPrev);
  const revPct = pctChange(revCurr, revPrev);

  // Recent reviews with user profiles
  const reviews: ReviewRow[] = reviewsRes?.data ?? [];
  if (reviews.length > 0) {
    const userIds = [...new Set(reviews.map((r) => r.user_id).filter(Boolean))] as string[];
    if (userIds.length > 0) {
      const { data: profiles } = await (supabase as any)
        .from('user_profiles')
        .select('user_id, display_name, avatar_url')
        .in('user_id', userIds);
      const profileMap: Record<string, { display_name: string; avatar_url: string | null }> = {};
      for (const p of profiles ?? []) profileMap[p.user_id] = p;
      for (const r of reviews) {
        if (r.user_id) r.user_profiles = profileMap[r.user_id] ?? null;
      }
    }
  }

  const bizStats = statsRes?.data ?? null;
  const avgRating = bizStats?.avg_rating ?? null;
  const totalReviews = bizStats?.reviews_count ?? 0;

  const coverUrl = buildMenuImageUrl(biz.cover_url, { width: 800, quality: 80 });
  const logoUrl = biz.logo_url ? buildMenuImageUrl(biz.logo_url, { width: 80, quality: 80 }) : null;

  // Recent activities (from reviews)
  const activities = reviews.slice(0, 4).map((r) => ({
    type: 'review' as const,
    title: 'Yeni yorum aldı',
    subtitle: r.content ? `"${r.content.slice(0, 50)}${r.content.length > 50 ? '…' : ''}"` : 'Yorum geldi',
    time: timeAgo(r.created_at),
  }));

  const STAT_CARDS = [
    {
      label: 'Görüntülenme',
      value: viewsTotal,
      pct: null,
      icon: <EyeStatIcon />,
      bg: '#eef2ff',
      color: '#6366f1',
    },
    {
      label: 'Favori Eklenme',
      value: favCurr,
      pct: favPct,
      icon: <HeartStatIcon />,
      bg: '#fff1f2',
      color: '#f43f5e',
    },
    {
      label: 'Yorum',
      value: revCurr,
      pct: revPct,
      icon: <ChatStatIcon />,
      bg: '#f5f3ff',
      color: '#8b5cf6',
    },
    {
      label: 'QR Tarama',
      value: summary.qr_scans,
      pct: null,
      icon: <QrStatIcon />,
      bg: '#f0fdf4',
      color: '#16a34a',
    },
    {
      label: 'Menü Açılma',
      value: summary.menu_opens,
      pct: null,
      icon: <SearchStatIcon />,
      bg: '#fffbeb',
      color: '#d97706',
    },
  ];

  const QUICK_ACTIONS = [
    { href: '/owner/menus', icon: <QAMenuIcon />, title: 'Menü Düzenle', sub: 'Menünüzü güncelleyin', bg: '#fff1f2', color: '#f43f5e' },
    { href: '/owner/businesses', icon: <QACameraIcon />, title: 'İşletme Bilgileri', sub: 'Bilgilerinizi düzenleyin', bg: '#f0fdf4', color: '#16a34a' },
    { href: '/owner/marketing/campaigns', icon: <QAMegaIcon />, title: 'Kampanya Oluştur', sub: 'Yeni kampanya ekleyin', bg: '#fff7ed', color: '#f97316' },
    { href: '/owner/qr', icon: <QAQrIcon />, title: 'QR Kodu İndir', sub: 'QR menünüzü indirin', bg: '#eef2ff', color: '#6366f1' },
    { href: '/owner/analytics', icon: <QAChartIcon />, title: 'İstatistikleri Gör', sub: 'Detaylı raporları inceleyin', bg: '#fefce8', color: '#ca8a04' },
  ];

  return (
    <div className="p-6 max-w-[1400px] mx-auto">
      {/* ── Greeting ──────────────────────────────────────────────── */}
      <div className="mb-6 flex items-start justify-between gap-4">
        <div>
          <h1 className="text-[22px] font-[900] text-[#1a1a2e]">Merhaba {firstName}! 👋</h1>
          <p className="mt-1 text-[13px] text-[#94a3b8] font-[600]">İşletmenizin son durumuna hızlıca göz atın.</p>
        </div>
        <div className="flex items-center gap-2 rounded-xl border border-[#e2e8f0] bg-white px-3 py-2 text-[12px] font-[800] text-[#475569]">
          <CalendarIcon />
          Son {DAYS} Gün
        </div>
      </div>

      {/* ── Stat cards ────────────────────────────────────────────── */}
      <div className="mb-6 grid grid-cols-2 gap-3 sm:grid-cols-3 lg:grid-cols-5">
        {STAT_CARDS.map((s) => (
          <div key={s.label} className="rounded-2xl border border-[#f0f0f0] bg-white p-4 shadow-[0_1px_3px_rgba(0,0,0,0.04)]">
            <div
              className="mb-3 flex h-9 w-9 items-center justify-center rounded-xl"
              style={{ background: s.bg, color: s.color }}
            >
              {s.icon}
            </div>
            <p className="text-[11px] font-[700] text-[#94a3b8] uppercase tracking-wide">{s.label}</p>
            <p className="mt-1 text-[22px] font-[900] text-[#1a1a2e] leading-tight">
              {s.value.toLocaleString('tr-TR')}
            </p>
            {s.pct !== null && (
              <p className={`mt-1 text-[11px] font-[800] ${s.pct >= 0 ? 'text-[#16a34a]' : 'text-[#dc2626]'}`}>
                {s.pct >= 0 ? '↑' : '↓'} %{Math.abs(s.pct)}
              </p>
            )}
            <p className="mt-0.5 text-[10px] text-[#cbd5e1] font-[600]">Önceki {DAYS} güne göre</p>
          </div>
        ))}
      </div>

      {/* ── Chart + Activities ────────────────────────────────────── */}
      <div className="mb-6 grid gap-4 lg:grid-cols-[1fr_320px]">
        {/* Chart */}
        <div className="rounded-2xl border border-[#f0f0f0] bg-white p-5 shadow-[0_1px_3px_rgba(0,0,0,0.04)]">
          <div className="mb-4 flex items-center justify-between">
            <h2 className="text-[14px] font-[900] text-[#1a1a2e]">Görüntülenme Grafiği</h2>
            <span className="rounded-lg border border-[#e2e8f0] px-3 py-1 text-[11px] font-[800] text-[#475569]">Günlük</span>
          </div>
          <div className="h-[220px]">
            <ViewsChart data={chartData} />
          </div>
        </div>

        {/* Activities */}
        <div className="rounded-2xl border border-[#f0f0f0] bg-white p-5 shadow-[0_1px_3px_rgba(0,0,0,0.04)]">
          <h2 className="mb-4 text-[14px] font-[900] text-[#1a1a2e]">Son Aktiviteler</h2>
          {activities.length === 0 ? (
            <p className="text-[13px] text-[#94a3b8]">Henüz aktivite yok</p>
          ) : (
            <div className="space-y-3">
              {activities.map((a, i) => (
                <div key={i} className="flex items-start gap-3">
                  <div className="flex h-7 w-7 shrink-0 items-center justify-center rounded-full bg-[#fff1f2] text-[#f43f5e]">
                    <HeartStatIcon size={13} />
                  </div>
                  <div className="min-w-0 flex-1">
                    <p className="text-[12px] font-[800] text-[#1a1a2e]">{a.title}</p>
                    <p className="truncate text-[11px] text-[#94a3b8] font-[600]">{a.subtitle}</p>
                  </div>
                  <span className="shrink-0 text-[10px] text-[#cbd5e1] font-[700]">{a.time}</span>
                </div>
              ))}
            </div>
          )}
          <Link href="/owner/activity" className="mt-4 flex items-center gap-1 text-[12px] font-[800] text-[#dc2626] hover:underline">
            Tüm Aktiviteler →
          </Link>
        </div>
      </div>

      {/* ── Quick actions ─────────────────────────────────────────── */}
      <div className="mb-6">
        <h2 className="mb-3 text-[14px] font-[900] text-[#1a1a2e]">Hızlı İşlemler</h2>
        <div className="grid grid-cols-2 gap-3 sm:grid-cols-3 lg:grid-cols-5">
          {QUICK_ACTIONS.map((qa) => (
            <Link
              key={qa.href}
              href={qa.href}
              className="flex flex-col items-center gap-2 rounded-2xl border border-[#f0f0f0] bg-white p-4 text-center hover:shadow-[0_4px_12px_rgba(0,0,0,0.06)] hover:-translate-y-0.5 transition-all shadow-[0_1px_3px_rgba(0,0,0,0.04)]"
            >
              <div
                className="flex h-10 w-10 items-center justify-center rounded-xl"
                style={{ background: qa.bg, color: qa.color }}
              >
                {qa.icon}
              </div>
              <p className="text-[12px] font-[800] text-[#1a1a2e]">{qa.title}</p>
              <p className="text-[10px] text-[#94a3b8] font-[600] leading-tight">{qa.sub}</p>
            </Link>
          ))}
        </div>
      </div>

      {/* ── Reviews + Business preview ────────────────────────────── */}
      <div className="mb-6 grid gap-4 lg:grid-cols-[1fr_340px]">
        {/* Reviews */}
        <div className="rounded-2xl border border-[#f0f0f0] bg-white p-5 shadow-[0_1px_3px_rgba(0,0,0,0.04)]">
          <div className="mb-4 flex items-center justify-between">
            <h2 className="text-[14px] font-[900] text-[#1a1a2e]">Yorumlar</h2>
            <Link href="/owner/reviews" className="text-[12px] font-[800] text-[#dc2626] hover:underline">
              Tümünü Gör →
            </Link>
          </div>
          {reviews.length === 0 ? (
            <p className="text-[13px] text-[#94a3b8]">Henüz yorum yok</p>
          ) : (
            <div className="divide-y divide-[#f8f9fb]">
              {reviews.map((r) => (
                <div key={r.id} className="py-4">
                  <div className="flex items-center gap-3 mb-2">
                    <ReviewerAvatar profile={r.user_profiles ?? null} />
                    <div className="flex-1 min-w-0">
                      <p className="text-[13px] font-[800] text-[#1a1a2e]">
                        {r.user_profiles?.display_name ?? 'Kullanıcı'}
                      </p>
                      <div className="flex items-center gap-2">
                        <StarRating rating={r.rating} />
                        <span className="text-[11px] text-[#94a3b8] font-[600]">{timeAgo(r.created_at)}</span>
                        {!r.owner_reply && (
                          <span className="rounded-full bg-[#fff1f2] px-2 py-0.5 text-[10px] font-[800] text-[#dc2626]">Yeni</span>
                        )}
                      </div>
                    </div>
                    <Link href="/owner/reviews" className="shrink-0 rounded-lg border border-[#e2e8f0] px-3 py-1 text-[11px] font-[800] text-[#475569] hover:bg-[#f8fafc]">
                      ↩ Yanıtla
                    </Link>
                  </div>
                  {r.content && (
                    <p className="text-[13px] text-[#475569] leading-relaxed line-clamp-2">{r.content}</p>
                  )}
                </div>
              ))}
            </div>
          )}
          <Link
            href="/owner/reviews"
            className="mt-2 flex w-full items-center justify-center rounded-xl border border-[#e2e8f0] py-2.5 text-[12px] font-[800] text-[#475569] hover:bg-[#f8fafc] transition-colors"
          >
            Tüm Yorumları Yönet
          </Link>
        </div>

        {/* Business preview */}
        <div className="rounded-2xl border border-[#f0f0f0] bg-white overflow-hidden shadow-[0_1px_3px_rgba(0,0,0,0.04)]">
          {/* Cover */}
          <div className="relative h-[160px] bg-gradient-to-br from-[#5c1515] to-[#dc2626]">
            {coverUrl && (
              <Image src={coverUrl} alt={biz.name} fill sizes="340px" className="object-cover" />
            )}
            {/* Logo overlay */}
            {logoUrl && (
              <div className="absolute bottom-0 left-1/2 -translate-x-1/2 translate-y-1/2">
                <Image
                  src={logoUrl}
                  alt={biz.name}
                  width={60}
                  height={60}
                  className="rounded-full border-4 border-white object-cover shadow-md"
                />
              </div>
            )}
          </div>

          <div className="pt-10 pb-5 px-5 text-center">
            <div className="flex items-center justify-center gap-1.5">
              <p className="text-[15px] font-[900] text-[#1a1a2e]">{biz.name}</p>
              {biz.is_verified && (
                <span className="text-[#2563eb]">
                  <svg width="16" height="16" viewBox="0 0 24 24" fill="currentColor">
                    <path d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" fillRule="evenodd" clipRule="evenodd" fill="none" stroke="currentColor" strokeWidth="2"/>
                  </svg>
                </span>
              )}
            </div>
            <p className="mt-0.5 text-[12px] text-[#94a3b8] font-[600]">{biz.category}</p>
            <div className="mt-2 flex items-center justify-center gap-3 text-[12px] text-[#475569]">
              {avgRating != null && (
                <span className="flex items-center gap-1 font-[800]">
                  <span className="text-[#f59e0b]">★</span>
                  {avgRating.toFixed(1)}
                  <span className="text-[#94a3b8] font-[600]">({totalReviews})</span>
                </span>
              )}
              <span className="h-3 w-px bg-[#e2e8f0]" />
              <span className={`font-[800] ${biz.is_active ? 'text-[#16a34a]' : 'text-[#94a3b8]'}`}>
                {biz.is_active ? 'Açık' : 'Kapalı'}
              </span>
            </div>
            <div className="mt-4 flex gap-2">
              <Link
                href="/owner/businesses"
                className="flex-1 rounded-xl border border-[#e2e8f0] py-2 text-[12px] font-[800] text-[#475569] hover:bg-[#f8fafc] transition-colors"
              >
                Sayfayı Düzenle
              </Link>
              {biz.slug && (
                <Link
                  href={`/isletme/${biz.slug}`}
                  target="_blank"
                  className="flex-1 rounded-xl py-2 text-[12px] font-[900] text-white transition-all hover:opacity-90"
                  style={{ background: 'linear-gradient(135deg, #7f1d1d, #dc2626)' }}
                >
                  Sayfayı Görüntüle
                </Link>
              )}
            </div>
          </div>
        </div>
      </div>

      {/* ── Premium banner ────────────────────────────────────────── */}
      <div className="flex items-center justify-between gap-4 rounded-2xl border border-[#fecdd3] bg-gradient-to-r from-[#fff1f2] to-[#fff5f5] p-5">
        <div className="flex items-center gap-4">
          <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-[#fecdd3] text-[20px]">
            🎁
          </div>
          <div>
            <p className="text-[14px] font-[900] text-[#1a1a2e]">Premium&apos;a Geçin</p>
            <p className="text-[12px] text-[#64748b] font-[600]">Daha fazla müşteriye ulaşın, öne çıkan işletmeler arasında yer alın.</p>
          </div>
        </div>
        <button
          className="shrink-0 flex items-center gap-2 rounded-xl px-4 py-2 text-[13px] font-[900] text-white transition-all hover:opacity-90"
          style={{ background: 'linear-gradient(135deg, #7f1d1d, #dc2626)' }}
        >
          Premium&apos;a Geç <span>›</span>
        </button>
      </div>
    </div>
  );
}

function ReviewerAvatar({ profile }: { profile: { display_name: string; avatar_url: string | null } | null }) {
  const name = profile?.display_name ?? 'K';
  if (profile?.avatar_url) {
    // eslint-disable-next-line @next/next/no-img-element
    return <img src={profile.avatar_url} alt={name} className="h-9 w-9 rounded-full object-cover border border-[#f0f0f0] shrink-0" />;
  }
  return (
    <div className="flex h-9 w-9 shrink-0 items-center justify-center rounded-full bg-[#f1f5f9] text-[13px] font-[900] text-[#475569]">
      {name.charAt(0).toUpperCase()}
    </div>
  );
}

function StarRating({ rating }: { rating: number }) {
  return (
    <div className="flex items-center gap-0.5">
      {[1, 2, 3, 4, 5].map((s) => (
        <svg key={s} width="11" height="11" viewBox="0 0 24 24" fill={s <= rating ? '#f59e0b' : 'none'} stroke="#f59e0b" strokeWidth="2">
          <polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2" />
        </svg>
      ))}
    </div>
  );
}

// ── Stat icons ─────────────────────────────────────────────────────────────────

function EyeStatIcon() {
  return (
    <svg width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z" />
      <circle cx="12" cy="12" r="3" />
    </svg>
  );
}

function HeartStatIcon({ size = 17 }: { size?: number }) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z" />
    </svg>
  );
}

function ChatStatIcon() {
  return (
    <svg width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z" />
    </svg>
  );
}

function QrStatIcon() {
  return (
    <svg width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <rect x="3" y="3" width="7" height="7" /><rect x="14" y="3" width="7" height="7" /><rect x="3" y="14" width="7" height="7" />
    </svg>
  );
}

function SearchStatIcon() {
  return (
    <svg width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z" />
      <polyline points="14 2 14 8 20 8" />
    </svg>
  );
}

function CalendarIcon() {
  return (
    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <rect x="3" y="4" width="18" height="18" rx="2" ry="2" /><line x1="16" y1="2" x2="16" y2="6" /><line x1="8" y1="2" x2="8" y2="6" /><line x1="3" y1="10" x2="21" y2="10" />
    </svg>
  );
}

// Quick action icons
function QAMenuIcon() { return <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><polyline points="14 2 14 8 20 8"/><line x1="16" y1="13" x2="8" y2="13"/><line x1="16" y1="17" x2="8" y2="17"/></svg>; }
function QACameraIcon() { return <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><rect x="4" y="2" width="16" height="20" rx="2"/><path d="M9 22V12h6v10"/></svg>; }
function QAMegaIcon() { return <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M3 11l19-9-9 19-2-8-8-2z"/></svg>; }
function QAQrIcon() { return <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><rect x="3" y="3" width="7" height="7"/><rect x="14" y="3" width="7" height="7"/><rect x="3" y="14" width="7" height="7"/></svg>; }
function QAChartIcon() { return <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><line x1="18" y1="20" x2="18" y2="10"/><line x1="12" y1="20" x2="12" y2="4"/><line x1="6" y1="20" x2="6" y2="14"/></svg>; }
