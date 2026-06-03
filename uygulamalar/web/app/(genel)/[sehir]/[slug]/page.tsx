import { cache } from 'react';
import type { Metadata } from 'next';
import Link from 'next/link';
import { notFound } from 'next/navigation';
import { PublicShell } from '@/src/ui/acik/yerlesim';
import { Container } from '@/src/ui/acik/ortak';
import { BusinessTile } from '@/src/ui/bilesenler/isletme-karti';
import { appConfig } from '@/src/lib/ayarlar';
import { createSupabasePublicClient } from '@/src/lib/taban/acik';

// Handles both /[sehir]/[ilce] and /[sehir]/[kategori] under a single dynamic segment.
// Slug is resolved to district or category by querying the DB.

type LocalBusiness = {
  id: string;
  name: string;
  slug: string;
  public_slug?: string | null;
  category?: string | null;
  city?: string | null;
  district?: string | null;
  is_verified?: boolean | null;
  avg_rating?: number | null;
  review_count?: number | null;
  price_level?: string | null;
  median_price_cents?: number | null;
  district_slug?: string | null;
  category_slug?: string | null;
};

export const revalidate = 3600;

type Props = { params: Promise<{ sehir: string; slug: string }> };

function slug2label(slug: string): string {
  return decodeURIComponent(slug)
    .split('-')
    .map((w) => w.charAt(0).toUpperCase() + w.slice(1))
    .join(' ');
}

function slugify(text: string): string {
  return text
    .toLowerCase()
    .replace(/ğ/g, 'g').replace(/ş/g, 's').replace(/ı/g, 'i')
    .replace(/ç/g, 'c').replace(/ö/g, 'o').replace(/ü/g, 'u')
    .replace(/\s+/g, '-').replace(/[^a-z0-9-]/g, '');
}

type PageMode = 'district' | 'category';

// cache() memoizes per-request: generateMetadata + page component share one DB call.
// Deterministic resolution: district_slug exact match wins over category_slug exact match.
// Partial ilike fallback covers categories whose slugify() output differs from category_slug
// (e.g. "Kahvaltı" → "kahvalti" in DB but URL param may vary), preserving old URL behaviour.
const resolveMode = cache(async (
  citySlug: string,   // URL param — already lowercase+slugified (e.g. "istanbul")
  slugParam: string,  // URL param — district or category slug (e.g. "besiktas", "kahve")
): Promise<{ mode: PageMode; businesses: LocalBusiness[] }> => {
  if (!process.env.NEXT_PUBLIC_SUPABASE_URL) return { mode: 'category', businesses: [] };
  try {
    const supabase = createSupabasePublicClient();

    // Single OR query — hits partial indexes on district_slug and category_slug.
    const { data } = await (supabase as any)
      .from('businesses')
      .select('id,name,slug,public_slug,category,city,district,is_verified,avg_rating,review_count,price_level,median_price_cents,district_slug,category_slug')
      .eq('is_active', true)
      .eq('city_slug', citySlug)
      .or(`district_slug.eq.${slugParam},category_slug.eq.${slugParam}`)
      .order('avg_rating', { ascending: false })
      .limit(60);

    const allResults: LocalBusiness[] = data ?? [];

    // District is always preferred when both match (deterministic — no count comparison).
    const districtBiz = allResults.filter((b) => b.district_slug === slugParam);
    const categoryBiz = allResults.filter((b) => b.category_slug === slugParam);

    if (districtBiz.length > 0) return { mode: 'district', businesses: districtBiz };
    if (categoryBiz.length > 0) return { mode: 'category', businesses: categoryBiz };

    // Partial match fallback: covers categories stored with different Turkish char mapping
    // (e.g. URL "kahvalti" while DB category is "Kahvaltı" → category_slug "kahvalti").
    // This path is uncommon after migration but preserves backward compatibility.
    const { data: partialData } = await (supabase as any)
      .from('businesses')
      .select('id,name,slug,public_slug,category,city,district,is_verified,avg_rating,review_count,price_level,median_price_cents')
      .eq('is_active', true)
      .eq('city_slug', citySlug)
      .ilike('category', `%${slugParam.replace(/-/g, ' ')}%`)
      .order('avg_rating', { ascending: false })
      .limit(60);

    if ((partialData?.length ?? 0) > 0) {
      return { mode: 'category', businesses: partialData };
    }

    return { mode: 'category', businesses: [] };
  } catch {
    return { mode: 'category', businesses: [] };
  }
});

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { sehir, slug } = await params;
  const cityLabel = slug2label(sehir);
  const slugLabel = slug2label(slug);
  const siteUrl = appConfig.siteUrl().replace(/\/$/, '');
  const canonical = `${siteUrl}/${sehir}/${slug}`;
  const { mode } = await resolveMode(sehir, slug);
  const title = mode === 'district'
    ? `${slugLabel}, ${cityLabel} — Restoran ve Menüler | Yeedoy`
    : `${slugLabel} — ${cityLabel} | Güncel Fiyatlar | Yeedoy`;
  const description = mode === 'district'
    ? `${slugLabel}'da işletmelerin güncel menüleri, fiyatları ve kullanıcı yorumları.`
    : `${cityLabel}'da ${slugLabel} kategorisinde öne çıkan restoranlar, güncel menü fiyatları ve topluluk yorumları.`;
  return {
    title,
    description,
    alternates: { canonical },
    openGraph: { title, description, url: canonical, locale: 'tr_TR' },
  };
}

export default async function SehirSlugPage({ params }: Props) {
  const { sehir, slug } = await params;
  const cityLabel = slug2label(sehir);
  const slugLabel = slug2label(slug);
  const siteUrl = appConfig.siteUrl().replace(/\/$/, '');
  const { mode, businesses } = await resolveMode(sehir, slug);

  if (businesses.length === 0) notFound();

  if (mode === 'district') {
    const categoryCount = new Map<string, number>();
    for (const b of businesses) {
      if (b.category) categoryCount.set(b.category, (categoryCount.get(b.category) ?? 0) + 1);
    }
    const categories = Array.from(categoryCount.entries()).sort((a, b) => b[1] - a[1]);
    const schema = {
      '@context': 'https://schema.org',
      '@type': 'CollectionPage',
      name: `${slugLabel}, ${cityLabel} Restoranları`,
      url: `${siteUrl}/${sehir}/${slug}`,
      breadcrumb: {
        '@type': 'BreadcrumbList',
        itemListElement: [
          { '@type': 'ListItem', position: 1, name: 'Yeedoy', item: siteUrl + '/' },
          { '@type': 'ListItem', position: 2, name: cityLabel, item: `${siteUrl}/${sehir}` },
          { '@type': 'ListItem', position: 3, name: slugLabel, item: `${siteUrl}/${sehir}/${slug}` },
        ],
      },
    };
    return (
      <PublicShell>
        <script type="application/ld+json" dangerouslySetInnerHTML={{ __html: JSON.stringify(schema) }} />
        <Container className="py-8">
          <nav className="mb-4 text-sm text-muted" aria-label="Breadcrumb">
            <ol className="flex flex-wrap items-center gap-1">
              <li><Link href="/" className="hover:text-primary">Ana Sayfa</Link></li>
              <li aria-hidden="true">›</li>
              <li><Link href={`/${sehir}`} className="hover:text-primary">{cityLabel}</Link></li>
              <li aria-hidden="true">›</li>
              <li className="font-[700] text-textStrong">{slugLabel}</li>
            </ol>
          </nav>
          <h1 className="mb-1 text-3xl font-[900] tracking-tight text-textStrong">{slugLabel}</h1>
          <p className="mb-8 text-muted">{slugLabel}, {cityLabel} · {businesses.length} işletme</p>
          <section>
            <h2 className="mb-3 text-lg font-[800] text-textStrong">Kategoriler</h2>
            <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-3">
              {categories.map(([cat, cnt]) => (
                <Link
                  key={cat}
                  href={`/${sehir}/${slug}/${slugify(cat)}`}
                  className="flex items-center justify-between rounded-2xl border border-border bg-card px-5 py-4 hover:border-primary/40 hover:shadow-sm transition-all"
                >
                  <span className="font-[800] text-textStrong">{cat}</span>
                  <span className="rounded-full bg-primary/10 px-2.5 py-0.5 text-xs font-[800] text-primary">{cnt}</span>
                </Link>
              ))}
            </div>
          </section>
        </Container>
      </PublicShell>
    );
  }

  const breadcrumbSchema = {
    '@context': 'https://schema.org',
    '@type': 'BreadcrumbList',
    itemListElement: [
      { '@type': 'ListItem', position: 1, name: 'Yeedoy', item: `${siteUrl}/` },
      { '@type': 'ListItem', position: 2, name: cityLabel, item: `${siteUrl}/${sehir}` },
      { '@type': 'ListItem', position: 3, name: slugLabel, item: `${siteUrl}/${sehir}/${slug}` },
    ],
  };
  const faqSchema = {
    '@context': 'https://schema.org',
    '@type': 'FAQPage',
    mainEntity: [
      {
        '@type': 'Question',
        name: `${cityLabel}'da ${slugLabel} fiyatları ne kadar?`,
        acceptedAnswer: { '@type': 'Answer', text: `${cityLabel}'da ${slugLabel} kategorisindeki restoranların güncel fiyatları Yeedoy'da listelenmiştir.` },
      },
      {
        '@type': 'Question',
        name: `${cityLabel}'da en iyi ${slugLabel} yerleri nereler?`,
        acceptedAnswer: { '@type': 'Answer', text: `${cityLabel}'da ${slugLabel} kategorisinde Yeedoy topluluğu tarafından önerilen işletmeler bu sayfada sıralanmaktadır.` },
      },
    ],
  };

  return (
    <PublicShell>
      <script type="application/ld+json" dangerouslySetInnerHTML={{ __html: JSON.stringify(breadcrumbSchema) }} />
      <script type="application/ld+json" dangerouslySetInnerHTML={{ __html: JSON.stringify(faqSchema) }} />
      <Container className="py-8">
        <nav className="mb-4 text-sm text-muted" aria-label="Breadcrumb">
          <ol className="flex flex-wrap items-center gap-1">
            <li><Link href="/" className="hover:text-primary">Ana Sayfa</Link></li>
            <li aria-hidden="true">›</li>
            <li><Link href={`/${sehir}`} className="hover:text-primary">{cityLabel}</Link></li>
            <li aria-hidden="true">›</li>
            <li className="font-[700] text-textStrong">{slugLabel}</li>
          </ol>
        </nav>
        <h1 className="mb-1 text-3xl font-[900] tracking-tight text-textStrong">
          {slugLabel} — {cityLabel}
        </h1>
        <p className="mb-8 text-muted">{businesses.length} işletme</p>
        <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-3">
          {businesses.map((b) => (
            <BusinessTile
              key={b.id}
              slug={b.public_slug ?? b.slug}
              name={b.name}
              category={b.category ?? undefined}
              subtitle={`${b.district ? b.district + ' · ' : ''}${b.city ?? cityLabel}`}
              isVerified={b.is_verified ?? false}
              qualityScore={b.avg_rating}
              priceLevel={b.price_level ?? undefined}
              medianPriceCents={b.median_price_cents ?? undefined}
            />
          ))}
        </div>
      </Container>
    </PublicShell>
  );
}
