import type { Metadata } from 'next';
import { PublicShell } from '@/src/ui/acik/yerlesim';
import { createSupabasePublicClient } from '@/src/lib/taban/acik';
import { OneriCanli } from '@/src/ui/acik/oneri-canli';
import type { OneriIsletme } from '@/src/ui/acik/oneri-canli';

export const metadata: Metadata = {
  title: 'Akıllı Öneri | Yeedoy',
  description: 'Zevklerine ve alışkanlıklarına göre senin için seçtik!',
  openGraph: { title: 'Akıllı Öneri | Yeedoy', description: 'Zevklerine göre kişisel restoran önerileri.' },
};

export const revalidate = 180;

export default async function OneriPage() {
  const sb = createSupabasePublicClient() as unknown as { from: (t: string) => any };

  const { data: statsRows } = await sb
    .from('businesses_with_stats')
    .select('id,name,category,city,district,is_verified,is_active,reviews_count,avg_rating')
    .eq('is_active', true)
    .order('avg_rating',    { ascending: false, nullsFirst: false })
    .order('reviews_count', { ascending: false, nullsFirst: false })
    .limit(32) as { data: any[] | null };

  const rows = statsRows ?? [];
  let businesses: OneriIsletme[] = [];

  if (rows.length > 0) {
    const ids = rows.map((r: any) => r.id as string);
    const { data: details } = await sb
      .from('businesses')
      .select('id,slug,public_slug,logo_url,cover_url')
      .in('id', ids) as { data: any[] | null };

    const detMap = new Map((details ?? []).map((d: any) => [d.id, d]));

    businesses = rows.map((row: any) => {
      const det = detMap.get(row.id);
      return {
        id:           row.id,
        name:         row.name,
        slug:         det?.public_slug ?? det?.slug ?? row.id,
        category:     row.category    ?? null,
        city:         row.city        ?? null,
        district:     row.district    ?? null,
        logoUrl:      det?.logo_url   ?? null,
        coverUrl:     det?.cover_url  ?? null,
        isVerified:   row.is_verified ?? false,
        reviewsCount: row.reviews_count ?? 0,
        avgRating:    row.avg_rating ? parseFloat(String(row.avg_rating)) : null,
      } satisfies OneriIsletme;
    });
  }

  return (
    <PublicShell>
      <OneriCanli businesses={businesses} />
    </PublicShell>
  );
}
