import type { Metadata } from 'next';
import { PublicShell } from '@/src/ui/acik/yerlesim';
import { createSupabasePublicClient } from '@/src/lib/taban/acik';
import { KampanyalarCanli } from '@/src/ui/acik/kampanyalar-canli';
import type { KampanyaGirdi } from '@/src/ui/acik/kampanyalar-canli';

export const metadata: Metadata = {
  title: 'Kampanyalar | Yeedoy',
  description: 'En güncel lezzet fırsatlarını ve indirimlerini keşfet.',
  openGraph: { title: 'Kampanyalar | Yeedoy', description: 'En güncel fırsatlar Yeedoy\'da.' },
};

export const revalidate = 300;

export default async function KampanyalarPage() {
  const sb = createSupabasePublicClient() as unknown as { from: (t: string) => any };

  // 1. Aktif kampanyalar (RLS: campaigns_public_read — herkes status='active' okuyabilir).
  //    Süresi dolmuş (ends_at geçmişte) kampanyalar hariç tutulur.
  const { data: campaignRows } = await sb
    .from('campaigns')
    .select('id,business_id,title,description,type,discount_percent,image_url,starts_at,ends_at,created_at')
    .eq('status', 'active')
    .or(`ends_at.is.null,ends_at.gt.${new Date().toISOString()}`)
    .order('created_at', { ascending: false })
    .limit(60) as { data: any[] | null };

  const campaigns = campaignRows ?? [];
  let list: KampanyaGirdi[] = [];

  if (campaigns.length > 0) {
    const businessIds = [...new Set(campaigns.map((c: any) => c.business_id as string))];

    const [{ data: statsRows }, { data: details }, { data: priceRows }] = await Promise.all([
      sb
        .from('businesses_with_stats')
        .select('id,name,category,city,district,is_verified,is_active,reviews_count,avg_rating')
        .in('id', businessIds) as Promise<{ data: any[] | null }>,
      sb
        .from('businesses')
        // Not: median_price_cents businesses tablosunda YOK (business_price_index_v1'de) —
        // buraya eklenirse PostgREST 42703 verir, tüm sorgu sessizce null döner ve slug
        // her zaman UUID'ye düşer. Bkz. get_smart_recommendations_v2 RPC'sindeki aynı desen.
        .select('id,slug,public_slug,logo_url,cover_url,price_level')
        .in('id', businessIds) as Promise<{ data: any[] | null }>,
      sb
        .from('business_price_index_v1')
        .select('business_id,median_price_cents')
        .in('business_id', businessIds) as Promise<{ data: any[] | null }>,
    ]);

    const statsMap = new Map((statsRows ?? []).map((r: any) => [r.id, r]));
    const detMap = new Map((details ?? []).map((d: any) => [d.id, d]));
    const priceMap = new Map((priceRows ?? []).map((p: any) => [p.business_id, p.median_price_cents]));

    list = campaigns
      .filter((c: any) => statsMap.get(c.business_id)?.is_active)
      .map((c: any): KampanyaGirdi => {
        const row = statsMap.get(c.business_id);
        const det = detMap.get(c.business_id);
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
          medianPriceCents: priceMap.get(c.business_id) ?? null,
          campaignId:          c.id,
          campaignTitle:       c.title,
          campaignDescription: c.description ?? null,
          campaignType:        c.type,
          discountPercent:     c.discount_percent ?? null,
          campaignImageUrl:    c.image_url ?? null,
          endsAt:              c.ends_at ?? null,
        };
      });
  }

  return (
    <PublicShell>
      <KampanyalarCanli campaigns={list} />
    </PublicShell>
  );
}
