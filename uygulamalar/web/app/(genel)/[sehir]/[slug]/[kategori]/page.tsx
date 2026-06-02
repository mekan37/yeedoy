import type { Metadata } from 'next';
import Link from 'next/link';
import { notFound } from 'next/navigation';
import { PublicShell } from '@/src/ui/acik/yerlesim';
import { Container } from '@/src/ui/acik/ortak';
import { BusinessTile } from '@/src/ui/bilesenler/isletme-karti';
import { appConfig } from '@/src/lib/ayarlar';
import { createSupabasePublicClient } from '@/src/lib/taban/acik';

type LocalBusiness = {
  id: string;
  name: string;
  slug: string;
  public_slug?: string | null;
  description?: string | null;
  logo_url?: string | null;
  cover_url?: string | null;
  category?: string | null;
  city?: string | null;
  district?: string | null;
  address?: string | null;
  is_verified?: boolean | null;
  is_active?: boolean;
  avg_rating?: number | null;
  review_count?: number | null;
  median_price_cents?: number | null;
};

export const revalidate = 3600;

type Props = {
  params: Promise<{ sehir: string; slug: string; kategori: string }>;
};

export async function generateStaticParams() {
  const supabase = createSupabasePublicClient();
  const { data } = await (supabase as any)
    .from('businesses')
    .select('city,district,category')
    .eq('is_active', true)
    .not('city', 'is', null)
    .not('district', 'is', null)
    .not('category', 'is', null)
    .limit(500);
  if (!data) return [];
  const slugify = (s: string) =>
    s.toLowerCase()
      .replace(/ğ/g, 'g').replace(/ş/g, 's').replace(/ı/g, 'i')
      .replace(/ç/g, 'c').replace(/ö/g, 'o').replace(/ü/g, 'u')
      .replace(/\s+/g, '-').replace(/[^a-z0-9-]/g, '');
  const seen = new Set<string>();
  const params: { sehir: string; slug: string; kategori: string }[] = [];
  for (const b of data) {
    const key = `${b.city}|${b.district}|${b.category}`;
    if (seen.has(key)) continue;
    seen.add(key);
    params.push({ sehir: slugify(b.city), slug: slugify(b.district), kategori: slugify(b.category) });
  }
  return params;
}

function slug2label(s: string) {
  return decodeURIComponent(s)
    .split('-')
    .map((w) => w.charAt(0).toUpperCase() + w.slice(1))
    .join(' ');
}

async function fetchBusinesses(city: string, district: string, category: string): Promise<LocalBusiness[]> {
  const supabase = createSupabasePublicClient();
  const { data } = await (supabase as any)
    .from('businesses')
    .select('id,name,slug,public_slug,description,logo_url,cover_url,category,city,district,address,is_verified,is_active,avg_rating,review_count,median_price_cents')
    .eq('is_active', true)
    .ilike('city', city)
    .ilike('district', district)
    .ilike('category', `%${category}%`)
    .order('avg_rating', { ascending: false })
    .limit(40);
  return (data ?? []) as LocalBusiness[];
}

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { sehir, slug, kategori } = await params;
  const cityLabel = slug2label(sehir);
  const districtLabel = slug2label(slug);
  const categoryLabel = slug2label(kategori);
  const siteUrl = appConfig.siteUrl().replace(/\/$/, '');
  const canonical = `${siteUrl}/${sehir}/${slug}/${kategori}`;
  return {
    title: `${categoryLabel} — ${districtLabel}, ${cityLabel} | Yeedoy`,
    description: `${districtLabel} ve ${cityLabel} çevresinde ${categoryLabel} kategorisinde öne çıkan restoranlar, menüler ve fiyatlar.`,
    alternates: { canonical },
    openGraph: { title: `${categoryLabel} — ${districtLabel}, ${cityLabel} | Yeedoy`, url: canonical },
  };
}

export default async function SehirSlugKategoriPage({ params }: Props) {
  const { sehir, slug, kategori } = await params;
  const cityLabel = slug2label(sehir);
  const districtLabel = slug2label(slug);
  const categoryLabel = slug2label(kategori);
  const siteUrl = appConfig.siteUrl().replace(/\/$/, '');

  const businesses = await fetchBusinesses(cityLabel, districtLabel, categoryLabel);
  if (businesses.length === 0 && sehir.length < 3) notFound();

  const breadcrumbSchema = {
    '@context': 'https://schema.org',
    '@type': 'BreadcrumbList',
    itemListElement: [
      { '@type': 'ListItem', position: 1, name: 'Yeedoy', item: siteUrl + '/' },
      { '@type': 'ListItem', position: 2, name: cityLabel, item: `${siteUrl}/${sehir}` },
      { '@type': 'ListItem', position: 3, name: districtLabel, item: `${siteUrl}/${sehir}/${slug}` },
      { '@type': 'ListItem', position: 4, name: categoryLabel, item: `${siteUrl}/${sehir}/${slug}/${kategori}` },
    ],
  };

  const faqSchema = {
    '@context': 'https://schema.org',
    '@type': 'FAQPage',
    mainEntity: [
      {
        '@type': 'Question',
        name: `${districtLabel}'da ${categoryLabel} fiyatları ne kadar?`,
        acceptedAnswer: { '@type': 'Answer', text: `${districtLabel} ve ${cityLabel} çevresinde ${categoryLabel} kategorisindeki restoranların güncel fiyatları Yeedoy'da listelenmiştir.` },
      },
      {
        '@type': 'Question',
        name: `${cityLabel}'da en iyi ${categoryLabel} yerleri nereler?`,
        acceptedAnswer: { '@type': 'Answer', text: `${cityLabel}'da ${categoryLabel} kategorisinde en yüksek Yeedoy puanına sahip işletmeler bu sayfada sıralanmaktadır.` },
      },
    ],
  };

  const itemListSchema = {
    '@context': 'https://schema.org',
    '@type': 'ItemList',
    name: `${categoryLabel} — ${districtLabel}, ${cityLabel}`,
    url: `${siteUrl}/${sehir}/${slug}/${kategori}`,
    numberOfItems: businesses.length,
    itemListElement: businesses.slice(0, 10).map((b, i) => ({
      '@type': 'ListItem',
      position: i + 1,
      item: {
        '@type': 'Restaurant',
        name: b.name,
        url: `${siteUrl}/isletme/${b.slug}`,
        servesCuisine: b.category,
        address: {
          '@type': 'PostalAddress',
          addressLocality: b.district ?? districtLabel,
          addressRegion: b.city ?? cityLabel,
          addressCountry: 'TR',
        },
        ...(b.avg_rating ? {
          aggregateRating: { '@type': 'AggregateRating', ratingValue: b.avg_rating.toFixed(1), reviewCount: b.review_count ?? 1 },
        } : {}),
      },
    })),
  };

  return (
    <PublicShell>
      <script type="application/ld+json" dangerouslySetInnerHTML={{ __html: JSON.stringify(breadcrumbSchema) }} />
      <script type="application/ld+json" dangerouslySetInnerHTML={{ __html: JSON.stringify(itemListSchema) }} />
      <script type="application/ld+json" dangerouslySetInnerHTML={{ __html: JSON.stringify(faqSchema) }} />
      <Container className="py-8">
        <nav className="mb-4 text-sm text-muted" aria-label="Breadcrumb">
          <ol className="flex flex-wrap items-center gap-1">
            <li><Link href="/" className="hover:text-primary">Ana Sayfa</Link></li>
            <li aria-hidden="true">›</li>
            <li><Link href={`/${sehir}`} className="hover:text-primary">{cityLabel}</Link></li>
            <li aria-hidden="true">›</li>
            <li><Link href={`/${sehir}/${slug}`} className="hover:text-primary">{districtLabel}</Link></li>
            <li aria-hidden="true">›</li>
            <li className="font-[700] text-textStrong">{categoryLabel}</li>
          </ol>
        </nav>
        <h1 className="mb-1 text-3xl font-[900] tracking-tight text-textStrong">{categoryLabel}</h1>
        <p className="mb-8 text-muted">{districtLabel}, {cityLabel} · {businesses.length} işletme</p>
        {businesses.length === 0 ? (
          <div className="rounded-2xl border border-border bg-card p-10 text-center">
            <p className="text-lg font-[800] text-textStrong">Sonuç bulunamadı</p>
            <p className="mt-2 text-sm text-muted">Bu bölgede henüz {categoryLabel} kategorisinde işletme kaydı yok.</p>
            <Link href="/kesif" className="mt-4 inline-block rounded-xl bg-primary px-4 py-2.5 text-sm font-[800] text-white">
              Tüm İşletmelere Bak
            </Link>
          </div>
        ) : (
          <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-3">
            {businesses.map((b) => (
              <BusinessTile
                key={b.id}
                slug={b.public_slug ?? b.slug}
                name={b.name}
                category={b.category ?? undefined}
                subtitle={`${b.district ?? districtLabel} · ${b.city ?? cityLabel}`}
                isVerified={b.is_verified ?? false}
                qualityScore={b.avg_rating}
                medianPriceCents={b.median_price_cents ?? undefined}
              />
            ))}
          </div>
        )}
      </Container>
    </PublicShell>
  );
}
