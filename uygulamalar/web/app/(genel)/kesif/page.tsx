import type { Metadata } from 'next';
import Link from 'next/link';
import { PublicShell } from '@/src/ui/acik/yerlesim';
import { Container } from '@/src/ui/acik/ortak';
import {
  BugunSpecials,
  BolgeselFiyatEndeksi,
  CategoryFilterChips,
  DiscoveryResults,
  FiyatAnomali,
  FiyatSinyalleri,
  HeroSearchSection,
  KampanyaHikayeleri,
} from '@/src/ui/acik/kesif';
import { getMarketplaceBusinesses, getTopMarketplaceBusinesses } from '@/src/lib/veri/pazar-okuma';
import { appConfig } from '@/src/lib/ayarlar';
import { createSupabasePublicClient } from '@/src/lib/taban/acik';

export const revalidate = 60;

type SearchParams = { q?: string; city?: string; category?: string; page?: string };

export function generateMetadata(): Metadata {
  const siteUrl = appConfig.siteUrl().replace(/\/$/, '');
  const canonical = `${siteUrl}/kesif`;
  return {
    title: 'Keşfet | Yeedoy',
    description: 'Restoran, kafe ve public menüleri kategori, şehir, yorum ve fiyat sinyalleriyle keşfet.',
    alternates: { canonical },
    openGraph: {
      title: 'Keşfet | Yeedoy',
      description: 'Şehrindeki işletmeleri ve menüleri keşfet.',
      url: canonical,
      images: [{ url: `${siteUrl}/sunucu/acik-grafik?title=Ke%C5%9Ffet`, width: 1200, height: 630, alt: 'Keşfet | Yeedoy' }],
    },
  };
}

export default async function DiscoverPage({ searchParams }: { searchParams: Promise<SearchParams> }) {
  const params = await searchParams;
  const q = params.q?.trim() ?? '';
  const city = params.city?.trim() ?? '';
  const category = params.category?.trim() ?? '';
  const page = Math.max(1, Number.parseInt(params.page ?? '1', 10) || 1);

  const isFiltered = Boolean(q || city || category);
  const supabase = createSupabasePublicClient();

  const [
    { data, count, totalPages },
    top,
    specials,
    priceSignals,
    anomaliData,
    cityData,
    campaignData,
  ] = await Promise.all([
    getMarketplaceBusinesses({ q, city, category, page, pageSize: 18 }),
    isFiltered ? Promise.resolve([]) : getTopMarketplaceBusinesses(6),

    // Bugünün spesiyali
    isFiltered
      ? Promise.resolve([])
      : (supabase as any)
          .rpc('get_today_specials_v1', { p_limit: 6 })
          .then((r: any) => (r?.data as any[]) ?? [])
          .catch(() => []),

    // Fiyat sinyalleri (en çok doğrulanan)
    isFiltered
      ? Promise.resolve([])
      : (supabase as any)
          .from('business_price_index_v1')
          .select('business_id,business_name,slug,verified_count,city,category')
          .order('verified_count', { ascending: false })
          .limit(4)
          .then((r: any) => (r?.data as any[]) ?? [])
          .catch(() => []),

    // Fiyat anomalisi — en uygun ve en pahalı
    isFiltered
      ? Promise.resolve([])
      : (supabase as any)
          .rpc('get_price_anomaly_businesses_v1', { p_limit: 4 })
          .then((r: any) => (r?.data as any[]) ?? [])
          .catch(() =>
            // Fallback: regional_price_index ile business join
            (supabase as any)
              .from('regional_price_index')
              .select('business_id,median_price_cents,city_avg_price_cents,diff_pct,business_name:businesses(name),slug:businesses(slug),category:businesses(category),city:businesses(city)')
              .not('diff_pct', 'is', null)
              .order('diff_pct', { ascending: true })
              .limit(4)
              .then((r: any) => {
                const rows = (r?.data as any[]) ?? [];
                return rows.map((row: any) => ({
                  business_id: row.business_id,
                  business_name: row.business_name?.name ?? null,
                  slug: row.slug?.slug ?? null,
                  city: row.city?.city ?? null,
                  category: row.category?.category ?? null,
                  median_price_cents: row.median_price_cents,
                  city_avg_price_cents: row.city_avg_price_cents,
                  diff_pct: row.diff_pct,
                }));
              })
              .catch(() => []),
          ),

    // Bölgesel fiyat endeksi — şehre göre ortalama
    isFiltered
      ? Promise.resolve([])
      : (supabase as any)
          .from('regional_price_index')
          .select('city:businesses(city),avg_price_cents:median_price_cents,business_count')
          .not('median_price_cents', 'is', null)
          .limit(50)
          .then((r: any) => {
            const rows = (r?.data as any[]) ?? [];
            // Group by city and compute averages
            const cityMap = new Map<string, { total: number; count: number; bizCount: number }>();
            for (const row of rows) {
              const c = row.city?.city ?? row.city ?? null;
              if (!c) continue;
              const entry = cityMap.get(c) ?? { total: 0, count: 0, bizCount: 0 };
              entry.total += row.avg_price_cents ?? row.median_price_cents ?? 0;
              entry.count += 1;
              entry.bizCount += row.business_count ?? 1;
              cityMap.set(c, entry);
            }
            return Array.from(cityMap.entries())
              .map(([c, e]) => ({ city: c, avg_price_cents: Math.round(e.total / e.count), business_count: e.bizCount }))
              .filter((x) => x.avg_price_cents > 0)
              .sort((a, b) => a.avg_price_cents - b.avg_price_cents)
              .slice(0, 6);
          })
          .catch(() => []),

    // Kampanya hikayeleri
    isFiltered
      ? Promise.resolve([])
      : (supabase as any)
          .from('business_campaigns')
          .select('id,business_id,title,description,discount_pct,valid_until,businesses(name,slug)')
          .eq('is_active', true)
          .gte('valid_until', new Date().toISOString())
          .order('created_at', { ascending: false })
          .limit(8)
          .then((r: any) => {
            const rows = (r?.data as any[]) ?? [];
            return rows.map((row: any) => ({
              id: row.id,
              business_id: row.business_id,
              business_name: row.businesses?.name ?? null,
              business_slug: row.businesses?.slug ?? null,
              title: row.title,
              description: row.description,
              discount_pct: row.discount_pct,
              valid_until: row.valid_until,
            }));
          })
          .catch(() => []),
  ]);

  return (
    <PublicShell>
      <main>
        <HeroSearchSection q={q} city={city} action="/kesif" />
        <section className="sticky top-16 z-30 border-b border-border bg-card shadow-sm">
          <Container>
            <div className="flex items-center gap-2 pb-0 pt-2">
              <span className="inline-flex min-h-[32px] items-center rounded-xl bg-primary px-3 text-xs font-[900] text-white">Liste</span>
              <Link href="/kesif/harita" className="inline-flex min-h-[32px] items-center rounded-xl px-3 text-xs font-[900] text-muted hover:bg-cardAlt">Harita</Link>
            </div>
            <CategoryFilterChips selected={category} city={city} q={q} basePath="/kesif" />
          </Container>
        </section>

        {/* Top işletmeler */}
        {top.length > 0 ? (
          <Container className="pb-4">
            <DiscoveryResults businesses={top} count={top.length} page={1} totalPages={1} basePath="/kesif" />
          </Container>
        ) : null}

        {/* Kampanya hikayeleri */}
        {campaignData.length > 0 ? (
          <Container className="pb-4">
            <KampanyaHikayeleri campaigns={campaignData} />
          </Container>
        ) : null}

        {/* Bugünün spesiyali */}
        {specials.length > 0 ? (
          <Container className="pb-4">
            <BugunSpecials specials={specials} />
          </Container>
        ) : null}

        {/* Fiyat anomalisi */}
        {anomaliData.length > 0 ? (
          <Container className="pb-4">
            <FiyatAnomali items={anomaliData} />
          </Container>
        ) : null}

        {/* Bölgesel fiyat endeksi */}
        {cityData.length > 0 ? (
          <Container className="pb-4">
            <BolgeselFiyatEndeksi cities={cityData} />
          </Container>
        ) : null}

        {/* Fiyat sinyalleri */}
        {priceSignals.length > 0 ? (
          <Container className="pb-4">
            <FiyatSinyalleri signals={priceSignals} />
          </Container>
        ) : null}

        {/* Tüm işletmeler */}
        <Container className="pb-12">
          <DiscoveryResults
            businesses={data}
            count={count}
            q={q}
            city={city}
            category={category}
            page={page}
            totalPages={totalPages}
            basePath="/kesif"
          />
        </Container>
      </main>
    </PublicShell>
  );
}
