import type { Metadata } from 'next';
import Link from 'next/link';
import { notFound } from 'next/navigation';
import { PublicShell } from '@/src/ui/acik/yerlesim';
import { Container } from '@/src/ui/acik/ortak';
import { appConfig } from '@/src/lib/ayarlar';
import { createSupabasePublicClient } from '@/src/lib/taban/acik';

export const revalidate = 3600;

type Props = { params: Promise<{ sehir: string; ilce: string }> };

function slugify(text: string): string {
  return text
    .toLowerCase()
    .replace(/ğ/g, 'g').replace(/ş/g, 's').replace(/ı/g, 'i')
    .replace(/ç/g, 'c').replace(/ö/g, 'o').replace(/ü/g, 'u')
    .replace(/\s+/g, '-').replace(/[^a-z0-9-]/g, '');
}

function slug2label(slug: string): string {
  return decodeURIComponent(slug)
    .split('-')
    .map((w) => w.charAt(0).toUpperCase() + w.slice(1))
    .join(' ');
}

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { sehir, ilce } = await params;
  const cityLabel = slug2label(sehir);
  const districtLabel = slug2label(ilce);
  const siteUrl = appConfig.siteUrl().replace(/\/$/, '');
  const canonical = `${siteUrl}/${sehir}/${ilce}`;

  const supabase = createSupabasePublicClient();
  const { count } = await (supabase as any)
    .from('businesses')
    .select('id', { count: 'exact', head: true })
    .eq('is_active', true)
    .ilike('city', cityLabel)
    .ilike('district', districtLabel) as { count: number | null };

  const businessCount = count ?? 0;
  const title = `${districtLabel}, ${cityLabel} — Restoran ve Menüler | Yeedoy`;
  const description = `${districtLabel}'da ${businessCount > 0 ? `${businessCount}+ ` : ''}işletmenin güncel menüleri, fiyatları ve kullanıcı yorumları.`;

  return {
    title,
    description,
    alternates: { canonical },
    openGraph: { title, description, url: canonical },
  };
}

export default async function DistrictHubPage({ params }: Props) {
  const { sehir, ilce } = await params;
  const cityLabel = slug2label(sehir);
  const districtLabel = slug2label(ilce);
  const siteUrl = appConfig.siteUrl().replace(/\/$/, '');

  const supabase = createSupabasePublicClient();

  const { data: businesses } = await (supabase as any)
    .from('businesses')
    .select('id, category')
    .eq('is_active', true)
    .ilike('city', cityLabel)
    .ilike('district', districtLabel)
    .not('category', 'is', null)
    .limit(500) as { data: Array<{ id: string; category: string }> | null };

  if (!businesses || businesses.length === 0) notFound();

  // Kategori sayıları
  const categoryCount = new Map<string, number>();
  for (const b of businesses) {
    categoryCount.set(b.category, (categoryCount.get(b.category) ?? 0) + 1);
  }
  const categories = Array.from(categoryCount.entries())
    .sort((a, b) => b[1] - a[1]);

  const schema = {
    '@context': 'https://schema.org',
    '@type': 'CollectionPage',
    name: `${districtLabel}, ${cityLabel} Restoranları`,
    url: `${siteUrl}/${sehir}/${ilce}`,
    breadcrumb: {
      '@type': 'BreadcrumbList',
      itemListElement: [
        { '@type': 'ListItem', position: 1, name: 'Yeedoy', item: siteUrl + '/' },
        { '@type': 'ListItem', position: 2, name: cityLabel, item: `${siteUrl}/${sehir}` },
        { '@type': 'ListItem', position: 3, name: districtLabel, item: `${siteUrl}/${sehir}/${ilce}` },
      ],
    },
  };

  return (
    <PublicShell>
      <script type="application/ld+json" dangerouslySetInnerHTML={{ __html: JSON.stringify(schema) }} />
      <Container className="py-8">
        {/* Breadcrumb */}
        <nav className="mb-4 text-sm text-muted" aria-label="Breadcrumb">
          <ol className="flex flex-wrap items-center gap-1">
            <li><Link href="/" className="hover:text-primary">Ana Sayfa</Link></li>
            <li aria-hidden="true">›</li>
            <li><Link href={`/${sehir}`} className="hover:text-primary">{cityLabel}</Link></li>
            <li aria-hidden="true">›</li>
            <li className="font-[700] text-textStrong">{districtLabel}</li>
          </ol>
        </nav>

        <h1 className="mb-1 text-3xl font-[900] tracking-tight text-textStrong">
          {districtLabel}
        </h1>
        <p className="mb-8 text-muted">
          {districtLabel}, {cityLabel} · {businesses.length} işletme
        </p>

        {/* Kategori grid */}
        <section>
          <h2 className="mb-3 text-lg font-[800] text-textStrong">Kategoriler</h2>
          <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-3">
            {categories.map(([cat, cnt]) => (
              <Link
                key={cat}
                href={`/${sehir}/${ilce}/${slugify(cat)}`}
                className="flex items-center justify-between rounded-2xl border border-border bg-card px-5 py-4 hover:border-primary/40 hover:shadow-sm transition-all"
              >
                <span className="font-[800] text-textStrong">{cat}</span>
                <span className="rounded-full bg-primary/10 px-2.5 py-0.5 text-xs font-[800] text-primary">
                  {cnt}
                </span>
              </Link>
            ))}
          </div>
        </section>
      </Container>
    </PublicShell>
  );
}
