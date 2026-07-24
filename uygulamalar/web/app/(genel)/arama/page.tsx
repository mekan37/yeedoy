import type { Metadata } from 'next';
import Link from 'next/link';
import { PublicShell } from '@/src/ui/acik/yerlesim';
import { Container, SectionHeader } from '@/src/ui/acik/ortak';
import { CategoryFilterChips, DiscoveryResults, SearchBar } from '@/src/ui/acik/kesif';
import { getMarketplaceBusinesses } from '@/src/lib/veri/pazar-okuma';
import { appConfig } from '@/src/lib/ayarlar';
import { RecentSearches } from './recent-searches-istemci';

type SearchParams = { q?: string; city?: string; category?: string; page?: string };

export function generateMetadata(): Metadata {
  const siteUrl = appConfig.siteUrl().replace(/\/$/, '');
  return {
    title: 'Arama | Yeedoy',
    description: 'Yeedoy işletme, kategori ve menü arama sonuçları.',
    alternates: { canonical: `${siteUrl}/arama` },
  };
}

const POPULAR_SEARCHES = [
  { label: 'Kebap', q: 'kebap' },
  { label: 'Kahvaltı', q: 'kahvaltı' },
  { label: 'Pizza', q: 'pizza' },
  { label: 'Burger', q: 'burger' },
  { label: 'Çorba', q: 'çorba' },
  { label: 'Baklava', q: 'baklava' },
  { label: 'Döner', q: 'döner' },
  { label: 'Pide', q: 'pide' },
];

const POPULAR_CITIES = ['İstanbul', 'Ankara', 'İzmir', 'Bursa', 'Antalya'];

export default async function SearchPage({ searchParams }: { searchParams: Promise<SearchParams> }) {
  const params = await searchParams;
  const q = params.q?.trim() ?? '';
  const city = params.city?.trim() ?? '';
  const category = params.category?.trim() ?? '';
  const page = Math.max(1, Number.parseInt(params.page ?? '1', 10) || 1);
  const hasQuery = Boolean(q || city || category);

  const { data, count, totalPages } = hasQuery
    ? await getMarketplaceBusinesses({ q, city, category, page, pageSize: 18 })
    : { data: [], count: 0, totalPages: 0 };

  return (
    <PublicShell>
      <main>
        <section className="border-b border-border bg-cardAlt py-8">
          <Container>
            <SectionHeader title="Ara" subtitle="İşletme, şehir veya kategori ara." className="mb-5" />
            <SearchBar q={q} city={city} action="/arama" />
          </Container>
        </section>

        {!hasQuery ? (
          <Container className="py-8">
            {/* Recent searches (client-side localStorage) */}
            <RecentSearches currentQ={q} />

            {/* Popular searches */}
            <section className="mb-8">
              <p className="mb-3 text-xs font-black uppercase tracking-wide text-muted">Popüler Aramalar</p>
              <div className="flex flex-wrap gap-2">
                {POPULAR_SEARCHES.map(({ label, q: pq }) => (
                  <Link
                    key={pq}
                    href={`/arama?q=${encodeURIComponent(pq)}`}
                    className="inline-flex min-h-[40px] items-center rounded-full border border-border bg-card px-4 text-sm font-bold text-textStrong hover:border-primary/40 hover:text-primary"
                  >
                    {label}
                  </Link>
                ))}
              </div>
            </section>

            {/* Cities */}
            <section className="mb-8">
              <p className="mb-3 text-xs font-black uppercase tracking-wide text-muted">Şehre Göre</p>
              <div className="flex flex-wrap gap-2">
                {POPULAR_CITIES.map((c) => (
                  <Link
                    key={c}
                    href={`/arama?city=${encodeURIComponent(c)}`}
                    className="inline-flex min-h-[40px] items-center gap-2 rounded-full border border-border bg-card px-4 text-sm font-bold text-textStrong hover:border-primary/40 hover:text-primary"
                  >
                    <span className="h-1.5 w-1.5 rounded-full bg-primary" />
                    {c}
                  </Link>
                ))}
              </div>
            </section>

            {/* Quick nav */}
            <section>
              <p className="mb-3 text-xs font-black uppercase tracking-wide text-muted">Keşfet</p>
              <div className="grid gap-3 sm:grid-cols-3">
                {[
                  { href: '/en-iyiler', label: 'En İyi İşletmeler', desc: 'Puan ve yorum sıralaması' },
                  { href: '/kesif', label: 'İşletme Keşfi', desc: 'Kategori ve konuma göre' },
                  { href: '/liderler', label: 'Haftalık Kahramanlar', desc: 'En aktif kullanıcılar' },
                ].map((item) => (
                  <Link
                    key={item.href}
                    href={item.href}
                    className="rounded-2xl border border-border bg-card p-4 hover:border-primary/25 hover:shadow-xs transition-all"
                  >
                    <p className="font-black text-textStrong">{item.label}</p>
                    <p className="mt-0.5 text-xs text-muted">{item.desc}</p>
                  </Link>
                ))}
              </div>
            </section>
          </Container>
        ) : (
          <>
            <Container className="py-4">
              <CategoryFilterChips selected={category} city={city} q={q} basePath="/arama" />
            </Container>
            <Container className="pb-12">
              <DiscoveryResults businesses={data} count={count} q={q} city={city} category={category} page={page} totalPages={totalPages} basePath="/arama" />
            </Container>
          </>
        )}
      </main>
    </PublicShell>
  );
}
