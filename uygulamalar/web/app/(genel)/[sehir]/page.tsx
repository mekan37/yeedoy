import type { Metadata } from 'next';
import Link from 'next/link';
import { notFound } from 'next/navigation';
import { PublicShell } from '@/src/ui/acik/yerlesim';
import { Container } from '@/src/ui/acik/ortak';
import { appConfig } from '@/src/lib/ayarlar';
import { createSupabasePublicClient } from '@/src/lib/taban/acik';

export const revalidate = 3600;

type Props = { params: Promise<{ sehir: string }> };

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

export async function generateStaticParams(): Promise<Array<{ sehir: string }>> {
  try {
    const supabase = createSupabasePublicClient();
    const { data } = await (supabase as any)
      .from('businesses')
      .select('city')
      .eq('is_active', true)
      .not('city', 'is', null)
      .limit(500) as { data: Array<{ city: string }> | null };

    if (!data) return [];
    const seen = new Set<string>();
    return data
      .map((b) => ({ sehir: slugify(b.city) }))
      .filter((p) => {
        if (!p.sehir || seen.has(p.sehir)) return false;
        seen.add(p.sehir);
        return true;
      });
  } catch {
    return [];
  }
}

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { sehir } = await params;
  const cityLabel = slug2label(sehir);
  const siteUrl = appConfig.siteUrl().replace(/\/$/, '');
  const canonical = `${siteUrl}/${sehir}`;

  const supabase = createSupabasePublicClient();
  const { count } = await (supabase as any)
    .from('businesses')
    .select('id', { count: 'exact', head: true })
    .eq('is_active', true)
    .ilike('city', cityLabel) as { count: number | null };

  const businessCount = count ?? 0;
  const title = `${cityLabel}'da Restoran, Kafe ve Menüler | Yeedoy`;
  const description = `${cityLabel}'da ${businessCount > 0 ? `${businessCount}+ ` : ''}işletmenin güncel menülerini keşfet. Fiyat şeffaflığı, kullanıcı yorumları ve fiyat geçmişi.`;

  return {
    title,
    description,
    alternates: { canonical },
    openGraph: { title, description, url: canonical },
  };
}

export default async function CityHubPage({ params }: Props) {
  const { sehir } = await params;
  const cityLabel = slug2label(sehir);
  const siteUrl = appConfig.siteUrl().replace(/\/$/, '');

  const supabase = createSupabasePublicClient();

  // İlçe + kategori sayıları
  const { data: combos } = await (supabase as any)
    .from('businesses')
    .select('district, category')
    .eq('is_active', true)
    .ilike('city', cityLabel)
    .not('district', 'is', null)
    .not('category', 'is', null)
    .limit(2000) as { data: Array<{ district: string; category: string }> | null };

  if (!combos || combos.length === 0) notFound();

  // İlçe → işletme sayısı
  const districtCount = new Map<string, number>();
  const districtCategories = new Map<string, Set<string>>();
  for (const row of combos) {
    const d = row.district;
    districtCount.set(d, (districtCount.get(d) ?? 0) + 1);
    if (!districtCategories.has(d)) districtCategories.set(d, new Set());
    districtCategories.get(d)!.add(row.category);
  }

  const districts = Array.from(districtCount.entries())
    .sort((a, b) => b[1] - a[1])
    .slice(0, 30);

  // Popüler kategoriler (tüm şehir genelinde)
  const categoryCount = new Map<string, number>();
  for (const row of combos) {
    categoryCount.set(row.category, (categoryCount.get(row.category) ?? 0) + 1);
  }
  const topCategories = Array.from(categoryCount.entries())
    .sort((a, b) => b[1] - a[1])
    .slice(0, 8);

  const schema = {
    '@context': 'https://schema.org',
    '@type': 'CollectionPage',
    name: `${cityLabel} Restoranları ve Menüleri`,
    url: `${siteUrl}/${sehir}`,
    description: `${cityLabel}'daki restoranlar, kafeler ve menüler.`,
    breadcrumb: {
      '@type': 'BreadcrumbList',
      itemListElement: [
        { '@type': 'ListItem', position: 1, name: 'Yeedoy', item: siteUrl + '/' },
        { '@type': 'ListItem', position: 2, name: cityLabel, item: `${siteUrl}/${sehir}` },
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
            <li className="font-[700] text-textStrong">{cityLabel}</li>
          </ol>
        </nav>

        <h1 className="mb-1 text-3xl font-[900] tracking-tight text-textStrong">
          {cityLabel}
        </h1>
        <p className="mb-8 text-muted">
          {combos.length} işletme · {districts.length} ilçe
        </p>

        {/* Popüler kategoriler */}
        {topCategories.length > 0 && (
          <section className="mb-8">
            <h2 className="mb-3 text-lg font-[800] text-textStrong">Popüler Kategoriler</h2>
            <div className="flex flex-wrap gap-2">
              {topCategories.map(([cat, cnt]) => (
                <Link
                  key={cat}
                  href={`/${sehir}/${slugify(districts[0]?.[0] ?? '')}/${slugify(cat)}`}
                  className="rounded-xl border border-border bg-card px-3 py-1.5 text-sm font-[700] text-textStrong hover:border-primary hover:text-primary transition-colors"
                >
                  {cat}
                  <span className="ml-1.5 text-xs font-[500] text-muted">{cnt}</span>
                </Link>
              ))}
            </div>
          </section>
        )}

        {/* İlçeler */}
        <section>
          <h2 className="mb-3 text-lg font-[800] text-textStrong">İlçeler</h2>
          <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-3">
            {districts.map(([district, cnt]) => {
              const cats = Array.from(districtCategories.get(district) ?? []).slice(0, 3);
              return (
                <Link
                  key={district}
                  href={`/${sehir}/${slugify(district)}`}
                  className="rounded-2xl border border-border bg-card p-4 hover:border-primary/40 hover:shadow-sm transition-all"
                >
                  <p className="font-[800] text-textStrong">{district}</p>
                  <p className="mt-0.5 text-xs text-muted">{cnt} işletme</p>
                  {cats.length > 0 && (
                    <p className="mt-2 text-xs text-muted">{cats.join(' · ')}</p>
                  )}
                </Link>
              );
            })}
          </div>
        </section>
      </Container>
    </PublicShell>
  );
}
