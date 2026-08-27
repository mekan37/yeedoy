import type { Metadata } from 'next';
import { PublicShell } from '@/src/ui/acik/yerlesim';
import { createSupabasePublicClient } from '@/src/lib/taban/acik';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { eslesmeYuzdesiHesapla } from '@/src/lib/oneri-eslesme';
import { OneriCanli } from '@/src/ui/acik/oneri-canli';
import type { OneriIsletme, OneriAktivite, OneriTercih } from '@/src/ui/acik/oneri-canli';

export const metadata: Metadata = {
  title: 'Akıllı Öneri | Yeedoy',
  description: 'Zevklerine ve alışkanlıklarına göre senin için seçtik!',
  openGraph: { title: 'Akıllı Öneri | Yeedoy', description: 'Zevklerine göre kişisel restoran önerileri.' },
  alternates: { canonical: '/oneri' },
};

export const revalidate = 0; // giriş yapmış kullanıcıya özel veri içerdiği için sayfa cache'lenmez

type BusinessRow = {
  id: string; name: string; category: string | null; city: string | null; district: string | null;
  is_verified: boolean | null; reviews_count: number | null; avg_rating: string | number | null;
};
type DetailRow = { id: string; slug: string | null; public_slug: string | null; logo_url: string | null; cover_url: string | null };

function toOneriIsletme(row: BusinessRow, det: DetailRow | undefined, eslesmeYuzde: number | null): OneriIsletme {
  return {
    id: row.id,
    name: row.name,
    slug: det?.public_slug ?? det?.slug ?? row.id,
    category: row.category ?? null,
    city: row.city ?? null,
    district: row.district ?? null,
    logoUrl: det?.logo_url ?? null,
    coverUrl: det?.cover_url ?? null,
    isVerified: row.is_verified ?? false,
    reviewsCount: row.reviews_count ?? 0,
    avgRating: row.avg_rating ? parseFloat(String(row.avg_rating)) : null,
    eslesmeYuzde,
  };
}

export default async function OneriPage() {
  const pub = createSupabasePublicClient() as unknown as { from: (t: string) => any };
  const auth = await createSupabaseServerClient();
  const { data: { user } } = await auth.auth.getUser();
  const authAny = auth as unknown as { from: (t: string) => any; rpc: (fn: string, args?: any) => any };

  // 1. Genel en-iyi işletme listesi (herkese açık, gerçek veri — değişmedi)
  const { data: statsRows } = await pub
    .from('businesses_with_stats')
    .select('id,name,category,city,district,is_verified,is_active,reviews_count,avg_rating')
    .eq('is_active', true)
    .order('avg_rating',    { ascending: false, nullsFirst: false })
    .order('reviews_count', { ascending: false, nullsFirst: false })
    .limit(32) as { data: BusinessRow[] | null };

  const rows = statsRows ?? [];
  const ids = rows.map((r) => r.id);
  const { data: details } = ids.length > 0
    ? await pub.from('businesses').select('id,slug,public_slug,logo_url,cover_url').in('id', ids) as { data: DetailRow[] | null }
    : { data: [] as DetailRow[] };
  const detMap = new Map((details ?? []).map((d) => [d.id, d]));

  let tercihler: OneriTercih[] = [];
  let secilmisler: OneriIsletme[] = [];
  let denemeler: OneriIsletme[] = [];
  let aktiviteler: OneriAktivite[] = [];

  if (!user) {
    // Giriş yapmamış: kişiselleştirme yok, sadece genel liste, %Uyum badge'i yok.
    secilmisler = rows.slice(0, 8).map((r) => toOneriIsletme(r, detMap.get(r.id), null));
  } else {
    const [{ data: prefRows }, { data: actRows }, favRes, revRes, visRes] = await Promise.all([
      authAny.rpc('get_my_category_preferences_v1', { p_limit: 3 }) as Promise<{ data: OneriTercih[] | null }>,
      authAny.rpc('get_my_recent_activity_v1', { p_limit: 3 }) as Promise<{ data: Array<{ business_id: string; activity_type: string; created_at: string }> | null }>,
      authAny.from('favorites').select('business_id').eq('user_id', user.id) as Promise<{ data: Array<{ business_id: string }> | null }>,
      authAny.from('reviews').select('business_id').eq('user_id', user.id) as Promise<{ data: Array<{ business_id: string }> | null }>,
      authAny.from('visits').select('business_id').eq('user_id', user.id) as Promise<{ data: Array<{ business_id: string }> | null }>,
    ]);

    tercihler = prefRows ?? [];

    const etkilesimliIdler = new Set([
      ...(favRes.data ?? []).map((r) => r.business_id),
      ...(revRes.data ?? []).map((r) => r.business_id),
      ...(visRes.data ?? []).map((r) => r.business_id),
    ]);

    secilmisler = rows.slice(0, 8).map((r) => {
      const det = detMap.get(r.id);
      const skor = eslesmeYuzdesiHesapla(r.category, tercihler, r.avg_rating ? parseFloat(String(r.avg_rating)) : null);
      return toOneriIsletme(r, det, skor);
    });

    denemeler = rows
      .filter((r) => !etkilesimliIdler.has(r.id))
      .slice(0, 8)
      .map((r) => {
        const det = detMap.get(r.id);
        const skor = eslesmeYuzdesiHesapla(r.category, tercihler, r.avg_rating ? parseFloat(String(r.avg_rating)) : null);
        return toOneriIsletme(r, det, skor);
      });

    const aktRows = actRows ?? [];
    const aktBusinessIds = aktRows.map((a) => a.business_id);
    const { data: aktDetails } = aktBusinessIds.length > 0
      ? await pub.from('businesses').select('id,name,slug,public_slug,logo_url').in('id', aktBusinessIds) as { data: Array<DetailRow & { name: string }> | null }
      : { data: [] as Array<DetailRow & { name: string }> };
    const aktBizMap = new Map((aktDetails ?? []).map((d) => [d.id, d]));

    aktiviteler = aktRows
      .map((a) => {
        const biz = aktBizMap.get(a.business_id);
        if (!biz) return null;
        return {
          businessId: a.business_id,
          businessName: biz.name,
          slug: biz.public_slug ?? biz.slug ?? a.business_id,
          activityType: a.activity_type as OneriAktivite['activityType'],
          createdAt: a.created_at,
        } satisfies OneriAktivite;
      })
      .filter((a): a is OneriAktivite => a !== null);
  }

  return (
    <PublicShell>
      <OneriCanli
        loggedIn={!!user}
        secilmisler={secilmisler}
        denemeler={denemeler}
        tercihler={tercihler}
        aktiviteler={aktiviteler}
      />
    </PublicShell>
  );
}
