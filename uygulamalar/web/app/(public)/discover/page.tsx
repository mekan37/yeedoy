import type { Metadata } from 'next';
import Link from 'next/link';
import { createSupabaseServerClient } from '@/src/lib/supabaseServer';
import { appConfig } from '@/src/lib/config';
import { AppSectionHeader } from '@/src/ui/components/app-section-header';
import { BusinessTile } from '@/src/ui/components/business-tile';

export const revalidate = 60;

export function generateMetadata(): Metadata {
  const siteUrl = appConfig.siteUrl().replace(/\/$/, '');
  const canonical = `${siteUrl}/discover`;
  return {
    title: 'Keşfet | Yeedoy',
    description: 'Şehrindeki en iyi restoranları ve menüleri keşfet',
    alternates: { canonical },
    openGraph: {
      title: 'Keşfet | Yeedoy',
      description: 'Şehrindeki en iyi restoranları ve menüleri keşfet',
      url: canonical,
      images: [{ url: `${siteUrl}/api/og?title=Ke%C5%9Ffet`, width: 1200, height: 630, alt: 'Keşfet | Yeedoy' }],
    },
  };
}

// ── Categories matching mobile discoveryHomeCategories ──────────────────────
const CATEGORIES = [
  { id: 'Restoran', label: 'Restoran' },
  { id: 'Kafe', label: 'Kafe' },
  { id: 'Fast Food', label: 'Fast Food' },
  { id: 'Dönerci', label: 'Döner' },
  { id: 'Pizza', label: 'Pizza' },
  { id: 'Burger', label: 'Burger' },
  { id: 'Pide / Lahmacun', label: 'Pide' },
  { id: 'Balık', label: 'Balık' },
  { id: 'Pastane', label: 'Pastane' },
  { id: 'Kahvaltı', label: 'Kahvaltı' },
  { id: 'Tatlıcı', label: 'Tatlı' },
  { id: 'Çorba', label: 'Çorba' },
];

const PAGE_SIZE = 20;

type Business = {
  id: string; name: string; slug: string;
  category: string | null; city: string | null;
  logo_url: string | null; is_active: boolean; is_verified: boolean;
};

type TopBiz = {
  id: string; name: string; category: string | null; city: string | null;
  avg_rating: number; reviews_count: number; score: number;
};

type SearchParams = { q?: string; city?: string; category?: string; page?: string };

export default async function DiscoverPage({ searchParams }: { searchParams: Promise<SearchParams> }) {
  const params = await searchParams;
  const q = params.q?.trim() ?? '';
  const city = params.city?.trim() ?? '';
  const category = params.category?.trim() ?? '';
  const page = Math.max(1, parseInt(params.page ?? '1', 10));
  const from = (page - 1) * PAGE_SIZE;
  const to = from + PAGE_SIZE - 1;
  const hasFilters = !!(q || city || category);

  const supabase = await createSupabaseServerClient();

  let bizQuery = (supabase as any)
    .from('businesses')
    .select('id, name, slug, category, city, logo_url, is_active, is_verified', { count: 'exact' })
    .eq('is_active', true)
    .order('created_at', { ascending: false })
    .range(from, to);

  if (q) bizQuery = bizQuery.ilike('name', `%${q}%`);
  if (city) bizQuery = bizQuery.eq('city', city);
  if (category) bizQuery = bizQuery.eq('category', category);

  const [bizRes, topRes] = await Promise.all([
    bizQuery as Promise<{ data: Business[] | null; count: number | null }>,
    !hasFilters
      ? (supabase as any).rpc('get_top_businesses_period_v1', { p_period: 'week', p_limit: 5 }) as Promise<{ data: TopBiz[] | null }>
      : Promise.resolve({ data: null }),
  ]);

  const businesses = bizRes.data ?? [];
  const total = bizRes.count ?? 0;
  const totalPages = Math.ceil(total / PAGE_SIZE);
  const topWeek = topRes.data ?? [];

  function buildHref(overrides: Partial<{ q: string; city: string; category: string; page: number }>) {
    const sp = new URLSearchParams();
    const merged = { q, city, category, page, ...overrides };
    if (merged.q) sp.set('q', merged.q);
    if (merged.city) sp.set('city', merged.city);
    if (merged.category) sp.set('category', merged.category);
    if (merged.page > 1) sp.set('page', String(merged.page));
    const qs = sp.toString();
    return `/discover${qs ? `?${qs}` : ''}`;
  }

  function catHref(cat: string) {
    const sp = new URLSearchParams();
    if (cat !== category) sp.set('category', cat);
    if (city) sp.set('city', city);
    const qs = sp.toString();
    return `/discover${qs ? `?${qs}` : ''}`;
  }

  return (
    <main className="min-h-screen bg-bg">
      {/* ── Hero search bar ────────────────────────────────────────────────── */}
      <section className="border-b border-border bg-cardAlt">
        <div className="mx-auto max-w-3xl px-4 py-8 sm:py-10">
          <h1 className="mb-1 text-2xl font-[900] text-textStrong sm:text-3xl">Keşfet</h1>
          <p className="mb-5 text-sm text-muted">Şehrindeki en iyi restoranları ve menüleri keşfet</p>

          {/* Search form */}
          <form method="GET" action="/discover" className="flex flex-wrap gap-2">
            <div className="relative min-w-[200px] flex-1">
              <span className="pointer-events-none absolute inset-y-0 left-3.5 flex items-center text-muted">
                <svg viewBox="0 0 24 24" className="h-4 w-4 fill-none stroke-current" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
                  <circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/>
                </svg>
              </span>
              <input type="text" name="q" defaultValue={q} placeholder="İşletme veya menü öğesi ara…"
                className="w-full rounded-2xl border border-border bg-card py-2.5 pl-9 pr-4 text-sm text-textStrong placeholder:text-muted focus:outline-none focus:ring-2 focus:ring-primary/30" />
            </div>
            <input type="text" name="city" defaultValue={city} placeholder="Şehir"
              className="w-28 rounded-2xl border border-border bg-card px-4 py-2.5 text-sm text-textStrong placeholder:text-muted focus:outline-none focus:ring-2 focus:ring-primary/30" />
            <button type="submit"
              className="min-h-[44px] rounded-2xl px-6 text-sm font-[800] text-white transition-all hover:-translate-y-px hover:brightness-105 active:scale-[0.97] focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary/30"
              style={{ background: 'var(--yd-gradient-primary)', boxShadow: 'var(--yd-shadow-primary)' }}>
              Ara
            </button>
            {hasFilters && (
              <Link href="/discover"
                className="inline-flex min-h-[44px] items-center rounded-2xl border border-border bg-card px-4 text-sm text-muted transition-colors hover:text-textStrong focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary/30">
                Temizle
              </Link>
            )}
          </form>
        </div>
      </section>

      <div className="mx-auto max-w-3xl px-4 py-6">

        {/* ── Category quick filters ─────────────────────────────────────── */}
        <div className="mb-6">
          <div className="flex gap-2 overflow-x-auto pb-1 [-ms-overflow-style:none] [scrollbar-width:none] [&::-webkit-scrollbar]:hidden">
            {/* All */}
            <Link href={buildHref({ category: '', page: 1 })}
              className={`inline-flex shrink-0 min-h-[40px] items-center gap-1.5 rounded-full border px-3.5 py-1 text-sm font-[800] transition-all duration-[150ms] focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary/30 ${!category ? 'bg-[var(--yd-color-primary-soft)] border-primary/40 text-primary' : 'bg-cardAlt border-border text-textStrong hover:border-borderStrong'}`}>
              Tümü
            </Link>
            {CATEGORIES.map((cat) => (
              <Link key={cat.id} href={catHref(cat.id)}
                className={`inline-flex shrink-0 min-h-[40px] items-center gap-1.5 rounded-full border px-3.5 py-1 text-sm font-[800] whitespace-nowrap transition-all duration-[150ms] focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary/30 ${category === cat.id ? 'bg-[var(--yd-color-primary-soft)] border-primary/40 text-primary' : 'bg-cardAlt border-border text-textStrong hover:border-borderStrong'}`}>
                {cat.label}
              </Link>
            ))}
          </div>
        </div>

        {/* ── Top businesses strip (only when no filter) ─────────────────── */}
        {!hasFilters && topWeek.length > 0 && (
          <section className="mb-8">
            <div className="mb-3 flex items-center justify-between">
              <AppSectionHeader title="Bu Haftanın En İyileri" />
              <Link href="/top" className="text-sm font-[700] text-primary hover:underline">Tümünü gör →</Link>
            </div>
            <div className="flex gap-3 overflow-x-auto pb-1 [-ms-overflow-style:none] [scrollbar-width:none] [&::-webkit-scrollbar]:hidden">
              {topWeek.map((biz, i) => (
                <Link key={biz.id} href={`/b/${biz.id}`}
                  className="flex w-44 shrink-0 flex-col gap-1.5 rounded-[20px] border border-border bg-cardAlt p-3.5 shadow-yd1 transition-all hover:-translate-y-0.5 hover:shadow-yd2 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary/30">
                  <div className="flex items-start justify-between gap-1">
                    <span className="text-[11px] font-[900] text-primary">#{i + 1}</span>
                    <span className="flex items-center gap-0.5 text-[11px] font-[800] text-amber-500">
                      <svg viewBox="0 0 24 24" className="h-3 w-3 fill-current" aria-hidden="true"><polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"/></svg>
                      {biz.avg_rating.toFixed(1)}
                    </span>
                  </div>
                  <p className="text-sm font-[900] leading-tight text-textStrong line-clamp-2">{biz.name}</p>
                  <p className="text-[11px] text-muted">{biz.category}{biz.city ? ` · ${biz.city}` : ''}</p>
                  <p className="text-[11px] text-muted">{biz.reviews_count} yorum</p>
                </Link>
              ))}
            </div>
          </section>
        )}

        {/* ── Results ────────────────────────────────────────────────────── */}
        <div className="mb-4 flex items-center justify-between">
          <p className="text-sm text-muted">
            {hasFilters
              ? total > 0 ? `${total} sonuç` : 'Sonuç bulunamadı'
              : `${total} işletme`}
          </p>
          {category && (
            <span className="rounded-full bg-[var(--yd-color-primary-soft)] px-3 py-0.5 text-xs font-[800] text-primary">
              {category}
            </span>
          )}
        </div>

        {businesses.length > 0 ? (
          <div className="mb-10 flex flex-col gap-3">
            {businesses.map((b) => (
              <BusinessTile key={b.id} slug={b.slug} name={b.name}
                category={b.category ?? undefined} subtitle={b.city ?? undefined}
                isVerified={b.is_verified} />
            ))}
          </div>
        ) : (
          <div className="rounded-[20px] border border-border bg-card px-5 py-16 text-center">
            <p className="font-[900] text-textStrong">Sonuç bulunamadı</p>
            <p className="mt-2 text-sm text-muted">Arama kriterlerinizi değiştirin veya temizleyin.</p>
            <Link href="/discover" className="mt-4 inline-block text-sm font-[700] text-primary hover:underline">
              Tüm işletmeleri göster →
            </Link>
          </div>
        )}

        {/* Pagination */}
        {totalPages > 1 && (
          <div className="flex items-center justify-center gap-2">
            {page > 1 && (
              <Link href={buildHref({ page: page - 1 })}
                className="inline-flex min-h-[44px] items-center rounded-2xl border border-border bg-card px-4 text-sm font-[800] text-textStrong transition-colors hover:border-primary focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary/30">
                ← Önceki
              </Link>
            )}
            <span className="px-2 text-sm text-muted">{page} / {totalPages}</span>
            {page < totalPages && (
              <Link href={buildHref({ page: page + 1 })}
                className="inline-flex min-h-[44px] items-center rounded-2xl border border-border bg-card px-4 text-sm font-[800] text-textStrong transition-colors hover:border-primary focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary/30">
                Sonraki →
              </Link>
            )}
          </div>
        )}
      </div>
    </main>
  );
}
