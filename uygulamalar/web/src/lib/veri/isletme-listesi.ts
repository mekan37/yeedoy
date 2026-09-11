import { createSupabasePublicClient } from '@/src/lib/taban/acik';

export type IsletmeListesiKarti = {
  id: string;
  name: string;
  slug: string;
  category: string | null;
  city: string | null;
  district: string | null;
  logoUrl: string | null;
  coverUrl: string | null;
  isVerified: boolean;
  reviewsCount: number;
  avgRating: number | null;
};

export type IsletmeListesiParams = {
  q?: string;
  category?: string;
  city?: string;
  sort?: 'rating' | 'reviews' | 'az';
  minRating?: number;
  verified?: boolean;
  limit?: number;
};

// /api/isletmeler route handler ile paylaşılan sorgu — sunucu bileşenlerinin
// (kesif/page.tsx) kendi API rotasına self-fetch yapmadan aynı veriyi
// üretebilmesi için tekilleştirildi.
export async function fetchIsletmelerListesi(params: IsletmeListesiParams = {}): Promise<{
  data: IsletmeListesiKarti[];
  total: number;
}> {
  const { q, category, city, sort = 'rating', minRating = 0, verified = false, limit = 24 } = params;
  const supabase = createSupabasePublicClient();
  const sb = supabase as unknown as { from: (t: string) => any };

  let statsQ = sb
    .from('businesses_with_stats')
    .select('id,name,category,city,district,is_verified,is_active,reviews_count,avg_rating')
    .eq('is_active', true)
    .limit(limit);

  if (q?.trim()) statsQ = statsQ.ilike('name', `%${q.trim()}%`);
  if (category) statsQ = statsQ.eq('category', category);
  if (city?.trim()) statsQ = statsQ.ilike('city', `%${city.trim()}%`);
  if (minRating > 0) statsQ = statsQ.gte('avg_rating', minRating);
  if (verified) statsQ = statsQ.eq('is_verified', true);

  if (sort === 'reviews') {
    statsQ = statsQ
      .order('reviews_count', { ascending: false, nullsFirst: false })
      .order('avg_rating', { ascending: false, nullsFirst: false });
  } else if (sort === 'az') {
    statsQ = statsQ.order('name', { ascending: true });
  } else {
    statsQ = statsQ
      .order('avg_rating', { ascending: false, nullsFirst: false })
      .order('reviews_count', { ascending: false, nullsFirst: false });
  }

  const { data: statsRows } = await statsQ as { data: any[] | null };
  const rows = statsRows ?? [];

  const detailMap = new Map<string, { slug: string; public_slug: string | null; logo_url: string | null; cover_url: string | null }>();
  if (rows.length > 0) {
    const ids = rows.map((r: any) => r.id as string);
    const { data: details } = await sb
      .from('businesses')
      .select('id,slug,public_slug,logo_url,cover_url')
      .in('id', ids) as { data: any[] | null };
    for (const d of details ?? []) detailMap.set(d.id, d);
  }

  const data = rows.map((row: any) => {
    const det = detailMap.get(row.id);
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
      avgRating: row.avg_rating ? parseFloat(row.avg_rating) : null,
    };
  });

  return { data, total: data.length };
}
