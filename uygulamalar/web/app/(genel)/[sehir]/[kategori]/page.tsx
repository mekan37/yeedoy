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
  category?: string | null;
  city?: string | null;
  district?: string | null;
  is_verified?: boolean | null;
  avg_rating?: number | null;
  review_count?: number | null;
  median_price_cents?: number | null;
};

export const revalidate = 86400;

type Props = { params: Promise<{ sehir: string; kategori: string }> };

function slug2label(slug: string) {
  return decodeURIComponent(slug)
    .split('-')
    .map((w) => w.charAt(0).toUpperCase() + w.slice(1))
    .join(' ');
}

async function fetchBusinesses(city: string, category: string): Promise<LocalBusiness[]> {
  const supabase = createSupabasePublicClient();
  const { data } = await (supabase as any)
    .from('businesses')
    .select('id,name,slug,public_slug,category,city,district,is_verified,avg_rating,review_count,median_price_cents')
    .eq('is_active', true)
    .ilike('city', city)
    .ilike('category', `%${category}%`)
    .order('avg_rating', { ascending: false })
    .limit(60);
  return (data ?? []) as LocalBusiness[];
}

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { sehir, kategori } = await params;
  const cityLabel = slug2label(sehir);
  const categoryLabel = slug2label(kategori);
  const siteUrl = appConfig.siteUrl().replace(/\/$/, '');
  const canonical = `${siteUrl}/${sehir}/${kategori}`;
  const title = `${categoryLabel} — ${cityLabel} | Güncel Fiyatlar | Yeedoy`;
  const description = `${cityLabel}'da ${categoryLabel} kategorisinde öne çıkan restoranlar, güncel menü fiyatları ve topluluk yorumları.`;
  return {
    title,
    description,
    alternates: { canonical },
    openGraph: { title, description, url: canonical, locale: 'tr_TR' },
  };
}

export default async function SehirKategoriPage({ params }: Props) {
  const { sehir, kategori } = await params;
  const cityLabel = slug2label(sehir);
  const categoryLabel = slug2label(kategori);

  const businesses = await fetchBusinesses(cityLabel, categoryLabel);
  if (businesses.length === 0 && sehir.length < 3) notFound();

  const siteUrl = appConfig.siteUrl().replace(/\/$/, '');

  const breadcrumbSchema = {
    '@context': 'https://schema.org',
    '@type': 'BreadcrumbList',
    itemListElement: [
      { '@type': 'ListItem', position: 1, name: 'Yeedoy', item: `${siteUrl}/` },
      { '@type': 'ListItem', position: 2, name: cityLabel, item: `${siteUrl}/${sehir}` },
      { '@type': 'ListItem', position: 3, name: categoryLabel, item: `${siteUrl}/${sehir}/${kategori}` },
    ],
  };

  const itemListSchema = {
    '@context': 'https://schema.org',
    '@type': 'ItemList',
    name: `${categoryLabel} — ${cityLabel}`,
    url: `${siteUrl}/${sehir}/${kategori}`,
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
          addressLocality: b.district ?? cityLabel,
          addressRegion: b.city ?? cityLabel,
          addressCountry: 'TR',
        },
        ...(b.avg_rating ? {
          aggregateRating: {
            '@type': 'AggregateRating',
            ratingValue: b.avg_rating.toFixed(1),
            reviewCount: b.review_count ?? 1,
          },
        } : {}),
      },
    })),
  };

  const faqSchema = {
    '@context': 'https://schema.org',
    '@type': 'FAQPage',
    mainEntity: [
      {
        '@type': 'Question',
        name: `${cityLabel}'da ${categoryLabel} fiyatları ne kadar?`,
        acceptedAnswer: { '@type': 'Answer', text: `${cityLabel}'da ${categoryLabel} kategorisindeki restoranların güncel fiyatları Yeedoy'da listelenmiştir. Fiyatlar menüye ve konuma göre değişmektedir.` },
      },
      {
        '@type': 'Question',
        name: `${cityLabel}'da en iyi ${categoryLabel} yerleri nereler?`,
        acceptedAnswer: { '@type': 'Answer', text: `${cityLabel}'da ${categoryLabel} kategorisinde Yeedoy topluluğu tarafından önerilen işletmeler bu sayfada en yüksek puana göre sıralanmaktadır.` },
      },
      {
        '@type': 'Question',
        name: `${cityLabel} ${categoryLabel} menüsü nasıl karşılaştırılır?`,
        acceptedAnswer: { '@type': 'Answer', text: `Her işletmenin Yeedoy sayfasında güncel menü fiyatları, fiyat geçmişi ve doğrulanmış kullanıcı yorumları yer almaktadır.` },
      },
    ],
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
            <li className="font-[700] text-textStrong">{categoryLabel}</li>
          </ol>
        </nav>

        <h1 className="mb-1 text-3xl font-[900] tracking-tight text-textStrong">
          {categoryLabel} — {cityLabel}
        </h1>
        <p className="mb-8 text-muted">{businesses.length} işletme</p>

        {businesses.length === 0 ? (
          <div className="rounded-2xl border border-border bg-card p-10 text-center">
            <p className="text-lg font-[800] text-textStrong">Sonuç bulunamadı</p>
            <p className="mt-2 text-sm text-muted">
              {cityLabel}&apos;da henüz {categoryLabel} kategorisinde işletme kaydı yok.
            </p>
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
                subtitle={`${b.district ? b.district + ' · ' : ''}${b.city ?? cityLabel}`}
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
