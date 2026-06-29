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

        {/* Labs: Bütçe kombolar + Tat ikizi */}
        {!isFiltered ? (
          <Container className="pb-4">
            <p className="mb-3 text-xs font-[700] uppercase tracking-wide text-muted">Keşif Araçları</p>
            <div className="grid grid-cols-1 gap-3 sm:grid-cols-2">
              <Link
                href="/kombo-onerileri"
                className="flex items-start gap-3 rounded-2xl border border-border bg-card p-4 shadow-yd1 transition-all hover:-translate-y-0.5 hover:border-primary/20 hover:shadow-yd2"
              >
                <div
                  className="flex h-10 w-10 shrink-0 items-center justify-center rounded-[14px] text-white"
                  style={{ background: 'linear-gradient(135deg, #5C1515 0%, #7F1D1D 100%)' }}
                  aria-hidden="true"
                >
                  <svg viewBox="0 0 24 24" className="h-5 w-5 fill-current" aria-hidden="true">
                    <path d="M11.8 10.9c-2.27-.59-3-1.2-3-2.15 0-1.09 1.01-1.85 2.7-1.85 1.78 0 2.44.85 2.5 2.1h2.21c-.07-1.72-1.12-3.3-3.21-3.81V3h-3v2.16c-1.94.42-3.5 1.68-3.5 3.61 0 2.31 1.91 3.46 4.7 4.13 2.5.6 3 1.48 3 2.41 0 .69-.49 1.79-2.7 1.79-2.06 0-2.87-.92-2.98-2.1h-2.2c.12 2.19 1.76 3.42 3.68 3.83V21h3v-2.15c1.95-.37 3.5-1.5 3.5-3.55 0-2.84-2.43-3.81-4.7-4.4z" />
                  </svg>
                </div>
                <div className="min-w-0">
                  <p className="font-[900] text-textStrong">Bütçe-Dostu Kombolar</p>
                  <p className="mt-0.5 text-xs text-muted">Kişi sayısı ve bütçene göre öneriler</p>
                </div>
              </Link>

              <Link
                href="/tat-ikizi"
                className="flex items-start gap-3 rounded-2xl border border-border bg-card p-4 shadow-yd1 transition-all hover:-translate-y-0.5 hover:border-primary/20 hover:shadow-yd2"
              >
                <div
                  className="flex h-10 w-10 shrink-0 items-center justify-center rounded-[14px] text-white"
                  style={{ background: 'linear-gradient(135deg, #5C1515 0%, #7F1D1D 100%)' }}
                  aria-hidden="true"
                >
                  <svg viewBox="0 0 24 24" className="h-5 w-5 fill-current" aria-hidden="true">
                    <path d="M16 11c1.66 0 2.99-1.34 2.99-3S17.66 5 16 5c-1.66 0-3 1.34-3 3s1.34 3 3 3zm-8 0c1.66 0 2.99-1.34 2.99-3S9.66 5 8 5C6.34 5 5 6.34 5 8s1.34 3 3 3zm0 2c-2.33 0-7 1.17-7 3.5V19h14v-2.5c0-2.33-4.67-3.5-7-3.5zm8 0c-.29 0-.62.02-.97.05 1.16.84 1.97 1.97 1.97 3.45V19h6v-2.5c0-2.33-4.67-3.5-7-3.5z" />
                  </svg>
                </div>
                <div className="min-w-0">
                  <p className="font-[900] text-textStrong">Tat İkizin</p>
                  <p className="mt-0.5 text-xs text-muted">Benzer damak tadındaki kullanıcıları bul</p>
                </div>
              </Link>
            </div>
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
