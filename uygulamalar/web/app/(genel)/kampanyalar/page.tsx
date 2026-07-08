import type { Metadata } from 'next';
import { PublicShell } from '@/src/ui/acik/yerlesim';
import { createSupabasePublicClient } from '@/src/lib/taban/acik';
import { KampanyalarCanli } from '@/src/ui/acik/kampanyalar-canli';
import type { IsletmeProp } from '@/src/ui/acik/kampanyalar-canli';

export const metadata: Metadata = {
  title: 'Kampanyalar | Yeedoy',
  description: 'En güncel lezzet fırsatlarını ve indirimlerini keşfet.',
  openGraph: { title: 'Kampanyalar | Yeedoy', description: 'En güncel fırsatlar Yeedoy\'da.' },
};

export const revalidate = 300;

export default async function KampanyalarPage() {
  const sb = createSupabasePublicClient() as unknown as { from: (t: string) => any };

  // 1. Sıralı işletme listesi — businesses_with_stats
  const { data: statsRows } = await sb
    .from('businesses_with_stats')
    .select('id,name,category,city,district,is_verified,is_active,reviews_count,avg_rating')
    .eq('is_active', true)
    .order('reviews_count', { ascending: false, nullsFirst: false })
    .limit(48) as { data: any[] | null };

  const rows = statsRows ?? [];
  let list: IsletmeProp[] = [];

  if (rows.length > 0) {
    const ids = rows.map((r: any) => r.id as string);
    const { data: details } = await sb
      .from('businesses')
      .select('id,slug,public_slug,logo_url,cover_url,price_level,median_price_cents')
      .in('id', ids) as { data: any[] | null };

    const detMap = new Map((details ?? []).map((d: any) => [d.id, d]));

    list = rows.map((row: any) => {
      const det = detMap.get(row.id);
      return {
        id:               row.id,
        name:             row.name,
        slug:             det?.public_slug ?? det?.slug ?? row.id,
        category:         row.category    ?? null,
        city:             row.city        ?? null,
        district:         row.district    ?? null,
        logoUrl:          det?.logo_url   ?? null,
        coverUrl:         det?.cover_url  ?? null,
        isVerified:       row.is_verified ?? false,
        reviewsCount:     row.reviews_count ?? 0,
        avgRating:        row.avg_rating ? parseFloat(row.avg_rating) : null,
        priceLevel:       det?.price_level ?? null,
        medianPriceCents: det?.median_price_cents ?? null,
      } satisfies IsletmeProp;
    });
  }

  return (
    <PublicShell>
      <KampanyalarCanli businesses={list} />
    </PublicShell>
  );
}
