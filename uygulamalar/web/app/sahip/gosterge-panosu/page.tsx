import type { Metadata } from 'next';
import Link from 'next/link';
import { redirect } from 'next/navigation';
import { Clock } from 'lucide-react';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { getOnboardingStatus } from '@/src/lib/veri/owner/sahip-baslangic-durumu';
import { PanelIcerikYuzeyi, PanelBolumKarti } from '@/src/ui/yerlesim/panel-section-card';
import { MetricCard } from '@/src/ui/bilesenler/olcum-karti';
import { getOwnerBusinessIds, getOwnerBusinessesByIds } from '@/src/lib/veri/owner/sahip-isletmeleri';
import { buildMenuImageUrl } from '@/src/lib/medya-adresi';
import { GoruntulenmeGrafigi, type GunlukGoruntulenme } from './goruntuleme-grafigi';
import { FEATURE_LABELS, PLAN_CEILING_FEATURE_KEYS } from '@/src/lib/plan/plan-sabitleri';

type PlanOzetVerisi = {
  plan_tier: string;
  features: Array<{ feature_key: string; enabled: boolean; limit_value: number | null; used: number }>;
};

export const metadata: Metadata = {
  title: 'Genel Bakış | Sahip Paneli',
  robots: { index: false, follow: false },
};

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
  city: string | null;
  district: string | null;
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

/** 7 günlük boş gün iskeleti (bugünden geriye) — sayaç haritalarını başlatmak için. */
function emptyDayMap(): Record<string, number> {
  const map: Record<string, number> = {};
  for (let i = 6; i >= 0; i--) {
    const d = new Date(Date.now() - i * 86400000);
    map[d.toISOString().slice(0, 10)] = 0;
  }
  return map;
}

/** İşletme başına günlük sayım haritası üretir — aynı satırlar hem trend hem grafik için kullanılır. */
function dailyByBusiness(rows: Array<{ business_id: string; created_at: string }>, ids: string[]): Map<string, GunlukGoruntulenme[]> {
  const perBiz = new Map<string, Record<string, number>>();
  for (const id of ids) perBiz.set(id, emptyDayMap());
  for (const row of rows) {
    const day = row.created_at.slice(0, 10);
    const map = perBiz.get(row.business_id);
    if (map && day in map) map[day] = (map[day] ?? 0) + 1;
  }
  const result = new Map<string, GunlukGoruntulenme[]>();
  for (const [id, map] of perBiz) {
    result.set(
      id,
      Object.entries(map).map(([gun, sayi]) => ({
        gun,
        etiket: new Date(gun).toLocaleDateString('tr-TR', { day: 'numeric', month: 'short' }),
        sayi,
      })),
    );
  }
  return result;
}

export default async function OwnerDashboardPage({ searchParams }: DashboardProps) {
  const { bilgi, isletme } = await searchParams;
  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();

  const [bizIds, profileRes] = await Promise.all([
    getOwnerBusinessIds(supabase as any, user!.id),
    (supabase as any)
      .from('user_profiles')
      .select('display_name, owner_onboarding_redirected_at')
      .eq('user_id', user!.id)
      .maybeSingle(),
  ]);
  const firstName = (profileRes.data?.display_name as string | null)?.trim().split(/\s+/)[0] || null;

  // İlk kez onaylanmış bir sahip, gösterge panosuna ilk girişte bir kez
  // Başlangıç Rehberi'ne yönlendirilir — sonraki tüm açılışlarda buraya
  // (Genel Bakış'a) doğrudan gelir. bkz. migration 20260817000006.
  if (bizIds.length > 0 && !profileRes.data?.owner_onboarding_redirected_at) {
    await (supabase as any)
      .from('user_profiles')
      .update({ owner_onboarding_redirected_at: new Date().toISOString() })
      .eq('user_id', user!.id);
    const onboarding = await getOnboardingStatus();
    if (!onboarding.complete) {
      redirect('/sahip/baslangic');
    }
  }

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

  // ── Çoklu işletme seçimi + işletme başına detay bloğu ─────────────────────
  const ownerBusinesses = await getOwnerBusinessesByIds<BizRow>(
    supabase as any,
    bizIds,
    'id, name, slug, category, city, district, logo_url, cover_url, is_verified, is_active',
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
  const planByBiz = new Map<string, PlanOzetVerisi>();
  const profileMap = new Map<string, { display_name: string | null; avatar_url: string | null }>();
  const saatDurumuByBiz = new Map<string, { isOpenNow: boolean | null; closeTime: string | null }>();
  let dailyViewsByBiz = new Map<string, GunlukGoruntulenme[]>();

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
            .then((r: { data: PlanOzetVerisi | null }) => [id, r?.data ?? undefined] as const)
            .catch(() => [id, undefined] as const),
        ),
      ),
    ]);

    // Bugün açık mı + kapanış saati — sadece ilk seçili işletme için (kart tek işletme gösteriyor).
    const saatResults = await Promise.all(
      selectedIds.map((id) =>
        (supabase as any)
          .rpc('get_business_hours_v1', { p_business_id: id })
          .then((r: { data: { weekly?: Array<{ day_of_week: number; close_time: string; is_closed: boolean }>; is_open_now?: boolean } | null }) => {
            const nowIstanbul = new Date(Date.now() + 3 * 60 * 60 * 1000);
            const todayDow = nowIstanbul.getUTCDay();
            const today = r?.data?.weekly?.find((row) => row.day_of_week === todayDow);
            return [id, {
              isOpenNow: r?.data?.is_open_now ?? null,
              closeTime: today && !today.is_closed ? today.close_time : null,
            }] as const;
          })
          .catch(() => [id, { isOpenNow: null, closeTime: null }] as const),
      ),
    );
    for (const [id, durum] of saatResults) saatDurumuByBiz.set(id, durum);

    for (const row of ((statsRes.data ?? []) as Array<{ id: string; avg_rating: number | null; reviews_count: number | null }>)) {
      statsMap.set(row.id, row);
    }
    for (const [id, count] of bucketize(favRes.data ?? [])) favByBiz.set(id, count);
    for (const [id, count] of bucketize(viewsRes.data ?? [])) viewsByBiz.set(id, count);
    for (const [id, count] of bucketize(opensRes.data ?? [])) opensByBiz.set(id, count);
    for (const [id, count] of bucketize(qrRes.data ?? [])) qrByBiz.set(id, count);
    for (const [id, count] of bucketize(reviewTrendRes.data ?? [])) reviewTrendByBiz.set(id, count);

    // Görüntülenme Grafiği — trend hesaplamasıyla aynı business_page_view satırlarından, günlük kırılım
    dailyViewsByBiz = dailyByBusiness(
      (viewsRes.data ?? []).filter((r: { created_at: string }) => r.created_at >= since7d),
      selectedIds,
    );

    const detailRows = (reviewDetailRes.data ?? []) as ReviewRow[];
    for (const id of selectedIds) reviewsByBiz.set(id, []);
    for (const row of detailRows) {
      reviewsByBiz.get(row.business_id)?.push(row);
    }

    for (const [id, plan] of (planResults as Array<readonly [string, PlanOzetVerisi | undefined]>)) {
      if (plan) planByBiz.set(id, plan);
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
    { href: '/sahip/menuler', title: 'Menü Düzenle', subtitle: 'Ürün ve kategorileri güncelle', icon: <MenuIcon />, tone: 'blue' as const },
    { href: '/sahip/isletmeler', title: 'İşletme Bilgileri', subtitle: 'Profil ve iletişim bilgilerini düzenle', icon: <BuildingIcon />, tone: 'purple' as const },
    { href: '/sahip/pazarlama/kampanyalar', title: 'Kampanya Oluştur', subtitle: 'Yeni bir pazarlama kampanyası başlat', icon: <CampaignIcon />, tone: 'pink' as const },
    { href: '/sahip/karekod', title: 'QR Kodu İndir', subtitle: 'QR Stüdyosu ile kod tasarla', icon: <QrIcon />, tone: 'green' as const },
    { href: '/sahip/analitik', title: 'İstatistikleri Gör', subtitle: 'Detaylı performans analizini incele', icon: <ChartIcon />, tone: 'orange' as const },
  ];

  return (
    <div className="flex flex-col">
      <PanelIcerikYuzeyi className="pt-6">
        <div className="flex flex-col gap-6">
          {/* ── Karşılama ── */}
          <div className="flex flex-wrap items-center justify-between gap-3">
            <div>
              <h1 className="text-2xl font-black tracking-tight text-textStrong">
                Merhaba{firstName ? ` ${firstName}` : ''}! 👋
              </h1>
              <p className="mt-1 text-sm text-muted">İşletmenizin son durumuna hızlıca göz atın.</p>
            </div>
            <span className="inline-flex items-center gap-1.5 rounded-xl border border-border bg-card px-3 py-2 text-xs font-extrabold text-textStrong">
              <CalendarIcon />
              Son 7 Gün
              <ChevronDownIcon />
            </span>
          </div>

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

          {/* ── İşletme seçici (birden fazla işletme varsa) ── */}
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

          {ownerBusinesses.length > 0 && selectedBusinesses.length === 0 && (
            <p className="text-sm text-muted">Görüntülemek için en az bir işletme seçin.</p>
          )}

          {/* ── İşletme başına gösterge paneli ── */}
          {selectedBusinesses.map((b) => {
            const stats = statsMap.get(b.id) ?? { avg_rating: null, reviews_count: null };
            const favTrend = favByBiz.get(b.id) ?? { curr: 0, prev: 0 };
            const viewsTrend = viewsByBiz.get(b.id) ?? { curr: 0, prev: 0 };
            const opensTrend = opensByBiz.get(b.id) ?? { curr: 0, prev: 0 };
            const qrTrend = qrByBiz.get(b.id) ?? { curr: 0, prev: 0 };
            const reviewTrend = reviewTrendByBiz.get(b.id) ?? { curr: 0, prev: 0 };
            const bizReviews = reviewsByBiz.get(b.id) ?? [];
            const plan = planByBiz.get(b.id);
            const dailyViews = dailyViewsByBiz.get(b.id) ?? [];

            return (
              <div key={b.id} className="flex flex-col gap-6">
                {/* 5 istatistik kartı */}
                <div className="grid grid-cols-2 gap-4 sm:grid-cols-3 lg:grid-cols-5">
                  <MetricCard
                    title="Görüntülenme"
                    value={viewsTrend.curr}
                    trend={{ value: pctChange(viewsTrend.curr, viewsTrend.prev), label: 'önceki 7 güne göre' }}
                    icon={<EyeIcon />}
                    tone="blue"
                  />
                  <MetricCard
                    title="Favori Eklenme"
                    value={favTrend.curr}
                    trend={{ value: pctChange(favTrend.curr, favTrend.prev), label: 'önceki 7 güne göre' }}
                    icon={<HeartIcon />}
                    tone="pink"
                  />
                  <MetricCard
                    title="Yorum"
                    value={reviewTrend.curr}
                    trend={{ value: pctChange(reviewTrend.curr, reviewTrend.prev), label: 'önceki 7 güne göre' }}
                    icon={<StarIcon />}
                    tone="purple"
                  />
                  <MetricCard
                    title="QR Tarama"
                    value={qrTrend.curr}
                    trend={{ value: pctChange(qrTrend.curr, qrTrend.prev), label: 'önceki 7 güne göre' }}
                    icon={<QrIcon />}
                    tone="green"
                  />
                  <MetricCard
                    title="Menü Açılma"
                    value={opensTrend.curr}
                    trend={{ value: pctChange(opensTrend.curr, opensTrend.prev), label: 'önceki 7 güne göre' }}
                    icon={<MenuIcon />}
                    tone="orange"
                  />
                </div>

                {/* Grafik + Son Aktiviteler */}
                <div className="grid gap-4 lg:grid-cols-3">
                  <PanelBolumKarti
                    title="Görüntülenme Grafiği"
                    className="lg:col-span-2"
                    actions={
                      <span className="inline-flex items-center gap-1 rounded-lg border border-border px-2.5 py-1.5 text-[11px] font-extrabold text-textStrong">
                        Günlük
                        <ChevronDownIcon />
                      </span>
                    }
                  >
                    <GoruntulenmeGrafigi data={dailyViews} />
                  </PanelBolumKarti>

                  <PanelBolumKarti title="Son Aktiviteler" noPadding>
                    {bizReviews.length === 0 ? (
                      <p className="px-5 py-8 text-center text-sm text-muted">Henüz aktivite yok</p>
                    ) : (
                      <ul className="divide-y divide-border">
                        {bizReviews.slice(0, 4).map((r) => (
                          <li key={r.id} className="flex items-start gap-3 px-5 py-3">
                            <span className="flex h-8 w-8 shrink-0 items-center justify-center rounded-full bg-rose-50 text-rose-600">
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
                </div>

                {/* Hızlı İşlemler */}
                <PanelBolumKarti title="Hızlı İşlemler">
                  <div className="grid grid-cols-2 gap-1 sm:grid-cols-3 lg:grid-cols-5">
                    {QUICK_ACTIONS.map((a) => (
                      <Link
                        key={a.href}
                        href={a.href}
                        className="group flex flex-col gap-2 rounded-xl p-4 transition-colors hover:bg-cardAlt"
                      >
                        <span className={`flex h-9 w-9 items-center justify-center rounded-lg ${QUICK_ACTION_TONE[a.tone]}`}>
                          {a.icon}
                        </span>
                        <span className="text-sm font-extrabold text-textStrong group-hover:text-primary">{a.title}</span>
                        <span className="text-xs leading-snug text-muted">{a.subtitle}</span>
                      </Link>
                    ))}
                  </div>
                </PanelBolumKarti>

                {/* Yorumlar + İşletme Sayfanız */}
                <div className="grid gap-4 lg:grid-cols-2">
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
                                  className="flex shrink-0 items-center gap-1 rounded-lg border border-border px-2.5 py-1.5 text-[11px] font-extrabold text-textStrong transition-colors hover:border-primary hover:text-primary"
                                >
                                  <ReplyIcon />
                                  Yanıtla
                                </Link>
                              </div>
                            </li>
                          );
                        })}
                      </ul>
                    )}
                  </PanelBolumKarti>

                  <BusinessPreviewCard
                    business={b}
                    avgRating={stats.avg_rating}
                    reviewsCount={stats.reviews_count}
                    saatDurumu={saatDurumuByBiz.get(b.id) ?? { isOpenNow: null, closeTime: null }}
                  />
                </div>

                <PlanKompaktRozet plan={plan} />
              </div>
            );
          })}
        </div>
      </PanelIcerikYuzeyi>
    </div>
  );
}

const QUICK_ACTION_TONE: Record<'blue' | 'pink' | 'purple' | 'green' | 'orange', string> = {
  blue: 'bg-blue-50 text-blue-600',
  pink: 'bg-rose-50 text-rose-600',
  purple: 'bg-violet-50 text-violet-600',
  green: 'bg-emerald-50 text-emerald-600',
  orange: 'bg-amber-50 text-amber-600',
};

function BusinessPreviewCard({
  business,
  avgRating,
  reviewsCount,
  saatDurumu,
}: {
  business: BizRow;
  avgRating: number | null;
  reviewsCount: number | null;
  saatDurumu: { isOpenNow: boolean | null; closeTime: string | null };
}) {
  const coverUrl = buildMenuImageUrl(business.cover_url, { width: 900, quality: 80 });
  const logoUrl = business.logo_url ? buildMenuImageUrl(business.logo_url, { width: 160, quality: 84 }) : null;

  return (
    <PanelBolumKarti title="İşletme Sayfanız" noPadding>
      <div className="overflow-hidden rounded-b-2xl">
        {/* Kapak fotoğrafı + ortalanmış logo taşması */}
        <div className="relative min-h-[130px] bg-textStrong/90">
          {coverUrl && (
            // eslint-disable-next-line @next/next/no-img-element
            <img src={coverUrl} alt="İşletme kapak fotoğrafı" className="absolute inset-0 h-full w-full object-cover" />
          )}
          <div className="absolute -bottom-8 left-1/2 flex h-16 w-16 -translate-x-1/2 items-center justify-center overflow-hidden rounded-full border-4 border-card bg-card text-xl font-black text-textStrong shadow-yd2">
            {logoUrl ? (
              // eslint-disable-next-line @next/next/no-img-element
              <img src={logoUrl} alt={business.name} className="h-full w-full object-cover" />
            ) : (
              business.name.charAt(0).toUpperCase()
            )}
          </div>
        </div>

        {/* Ortalanmış içerik */}
        <div className="flex flex-col items-center gap-1 px-4 pb-5 pt-11 text-center">
          <div className="flex items-center gap-1.5">
            <p className="text-base font-black text-textStrong">{business.name}</p>
            {business.is_verified && (
              <span className="shrink-0 text-primary">
                <CheckBadgeIcon />
              </span>
            )}
          </div>
          <p className="text-xs font-bold text-muted">
            {business.category ?? 'Kategori yok'}
            {(business.city || business.district) ? ` · ${[business.district, business.city].filter(Boolean).join(', ')}` : ''}
          </p>
          <p className="text-xs font-bold text-muted">
            {avgRating != null && `★ ${avgRating.toFixed(1)} (${reviewsCount ?? 0})`}
            {!business.is_active ? (
              <>
                {avgRating != null && ' · '}
                <span className="text-zinc-500">Pasif</span>
              </>
            ) : saatDurumu.isOpenNow != null && (
              <>
                {avgRating != null && ' · '}
                <span className={saatDurumu.isOpenNow ? 'text-green-700' : 'text-(--yd-color-danger)'}>
                  {saatDurumu.isOpenNow ? 'Açık' : 'Kapalı'}
                </span>
                {saatDurumu.isOpenNow && saatDurumu.closeTime && ` · Kapanış ${saatDurumu.closeTime}`}
              </>
            )}
          </p>

          <div className="mt-3 flex items-center gap-2">
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
    </PanelBolumKarti>
  );
}

function PlanKompaktRozet({ plan }: { plan: PlanOzetVerisi | undefined }) {
  if (!plan) return null;

  if (plan.plan_tier === 'free') {
    return (
      <div className="mt-3 flex items-center justify-between gap-3 rounded-xl border border-amber-200 bg-amber-50 px-4 py-3">
        <p className="text-xs font-bold text-amber-800">
          Ücretsiz plandasınız — daha fazla özellik için yükseltin.
        </p>
        <Link href="/sahip/premium" className="shrink-0 text-xs font-extrabold text-amber-800 underline">
          Planları Gör
        </Link>
      </div>
    );
  }

  const kritikOzellik = plan.features.find(
    (f) =>
      f.enabled &&
      f.limit_value !== null &&
      f.used >= f.limit_value * 0.8 &&
      !(PLAN_CEILING_FEATURE_KEYS as readonly string[]).includes(f.feature_key),
  );

  if (!kritikOzellik) return null;

  return (
    <div className="mt-3 flex items-center justify-between gap-3 rounded-xl border border-border bg-cardAlt px-4 py-3">
      <p className="text-xs font-bold text-textStrong">
        {FEATURE_LABELS[kritikOzellik.feature_key as keyof typeof FEATURE_LABELS] ?? kritikOzellik.feature_key}: {kritikOzellik.used}/{kritikOzellik.limit_value} kullanıldı
      </p>
      <Link href="/sahip/ayarlar/plan" className="shrink-0 text-xs font-extrabold text-primary underline">
        Detay
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
    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <rect x="4" y="2" width="16" height="20" rx="2" ry="2" />
      <path d="M9 22V12h6v10" />
    </svg>
  );
}

function MenuIcon() {
  return (
    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z" />
      <polyline points="14 2 14 8 20 8" />
      <line x1="16" y1="13" x2="8" y2="13" />
      <line x1="16" y1="17" x2="8" y2="17" />
    </svg>
  );
}

function QrIcon() {
  return (
    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <rect x="3" y="3" width="7" height="7" /><rect x="14" y="3" width="7" height="7" /><rect x="3" y="14" width="7" height="7" />
    </svg>
  );
}

function StarIcon({ size = 18 }: { size?: number }) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2" />
    </svg>
  );
}

function EyeIcon() {
  return (
    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M1 12s4-7 11-7 11 7 11 7-4 7-11 7-11-7-11-7z" />
      <circle cx="12" cy="12" r="3" />
    </svg>
  );
}

function HeartIcon() {
  return (
    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M20.8 4.6a5.5 5.5 0 0 0-7.8 0L12 5.7l-1-1.1a5.5 5.5 0 0 0-7.8 7.8l1 1L12 21l7.8-7.8 1-1a5.5 5.5 0 0 0 0-7.6z" />
    </svg>
  );
}

function ChartIcon() {
  return (
    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <line x1="12" y1="20" x2="12" y2="10" />
      <line x1="18" y1="20" x2="18" y2="4" />
      <line x1="6" y1="20" x2="6" y2="16" />
    </svg>
  );
}

function CampaignIcon() {
  return (
    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M3 11l18-6v14l-18-6v-2z" />
      <path d="M7 15v4a2 2 0 0 0 2 2h1v-6" />
    </svg>
  );
}

function CalendarIcon() {
  return (
    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <rect x="3" y="4" width="18" height="18" rx="2" ry="2" />
      <line x1="16" y1="2" x2="16" y2="6" />
      <line x1="8" y1="2" x2="8" y2="6" />
      <line x1="3" y1="10" x2="21" y2="10" />
    </svg>
  );
}

function ChevronDownIcon() {
  return (
    <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round" className="shrink-0 text-muted">
      <polyline points="6 9 12 15 18 9" />
    </svg>
  );
}

function ReplyIcon() {
  return (
    <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <polyline points="9 17 4 12 9 7" />
      <path d="M20 18v-2a4 4 0 0 0-4-4H4" />
    </svg>
  );
}

function CheckBadgeIcon() {
  return (
    <svg width="18" height="18" viewBox="0 0 24 24" fill="currentColor" aria-hidden="true">
      <path d="M12 2 9.5 4.5 6 4l-.5 3.5L2 9l2 3-2 3 3.5 1.5L6 20l3.5-.5L12 22l2.5-2.5L18 20l.5-3.5L22 15l-2-3 2-3-3.5-1.5L18 4l-3.5.5z" />
      <path d="M9 12l2 2 4-4" stroke="white" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" fill="none" />
    </svg>
  );
}
