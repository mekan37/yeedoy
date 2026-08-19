import type { Metadata } from 'next';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { buildMenuImageUrl } from '@/src/lib/medya-adresi';
import { getOwnerBusinessIds } from '@/src/lib/veri/owner/sahip-isletmeleri';
import { IsletmelerimIstemcisi, type IsletmelerimSatiri } from './isletmelerim-istemcisi';

export const metadata: Metadata = {
  title: 'İşletmelerim | Sahip Paneli',
  robots: { index: false, follow: false },
};

type BizRow = {
  id: string;
  name: string;
  slug: string | null;
  logo_url: string | null;
  cover_url: string | null;
  category: string;
  city: string | null;
  district: string | null;
  is_active: boolean;
  created_at: string;
};

export default async function OwnerBusinessesPage() {
  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();

  const businessIds = await getOwnerBusinessIds(supabase as any, user!.id);

  const [{ data: businesses }, { data: pendingClaims }] = await Promise.all([
    businessIds.length > 0
      ? (supabase as any)
          .from('businesses')
          .select('id, name, slug, logo_url, cover_url, category, city, district, is_active, created_at')
          .in('id', businessIds)
          .order('created_at', { ascending: true }) as Promise<{ data: BizRow[] | null }>
      : Promise.resolve({ data: [] }),
    (supabase as any)
      .from('owner_claims')
      .select('id')
      .eq('user_id', user!.id)
      .eq('status', 'pending'),
  ]);

  const list = businesses ?? [];
  const pendingCount = pendingClaims?.length ?? 0;

  let statsMap = new Map<string, { avg_rating: number | null; reviews_count: number | null }>();
  let saatByBiz = new Map<string, { isOpenNow: boolean | null; closeTime: string | null }>();
  let trendByBiz = new Map<string, number>();

  if (list.length > 0) {
    const ids = list.map((b) => b.id);
    const since7d = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString();
    const since14d = new Date(Date.now() - 14 * 24 * 60 * 60 * 1000).toISOString();

    const [statsRes, viewsRes, hoursResults] = await Promise.all([
      (supabase as any).from('businesses_with_stats').select('id, avg_rating, reviews_count').in('id', ids),
      (supabase as any).from('analytics_events').select('business_id, created_at').in('business_id', ids).eq('event_name', 'business_page_view').gte('created_at', since14d),
      Promise.all(
        ids.map((id: string) =>
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
      ),
    ]);

    statsMap = new Map((statsRes.data ?? []).map((r: { id: string; avg_rating: number | null; reviews_count: number | null }) => [r.id, r]));
    saatByBiz = new Map(hoursResults);

    const trendCounts = new Map<string, { curr: number; prev: number }>();
    for (const id of ids) trendCounts.set(id, { curr: 0, prev: 0 });
    for (const row of (viewsRes.data ?? []) as Array<{ business_id: string; created_at: string }>) {
      const entry = trendCounts.get(row.business_id);
      if (!entry) continue;
      if (row.created_at >= since7d) entry.curr += 1;
      else entry.prev += 1;
    }
    for (const [id, c] of trendCounts) {
      trendByBiz.set(id, c.prev === 0 ? (c.curr > 0 ? 100 : 0) : Math.round(((c.curr - c.prev) / c.prev) * 100));
    }
  }

  const satirlar: IsletmelerimSatiri[] = list.map((b, i) => {
    const stats = statsMap.get(b.id) ?? { avg_rating: null, reviews_count: null };
    const saat = saatByBiz.get(b.id) ?? { isOpenNow: null, closeTime: null };
    return {
      id: b.id,
      name: b.name,
      slug: b.slug,
      category: b.category,
      city: b.city,
      district: b.district,
      isActive: b.is_active,
      isPrimary: i === 0,
      photoUrl: buildMenuImageUrl(b.cover_url ?? b.logo_url, { width: 200, quality: 80 }),
      avgRating: stats.avg_rating,
      reviewsCount: stats.reviews_count,
      viewTrendPct: trendByBiz.get(b.id) ?? 0,
      isOpenNow: saat.isOpenNow,
      closeTime: saat.closeTime,
    };
  });

  return (
    <IsletmelerimIstemcisi
      satirlar={satirlar}
      pendingCount={pendingCount}
    />
  );
}
