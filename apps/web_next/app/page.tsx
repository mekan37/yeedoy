import type { Metadata } from 'next';
import Link from 'next/link';
import { createSupabaseServerClient } from '@/src/lib/supabaseServer';
import { discoverBusinesses, getTopBusinesses } from '@/src/lib/db/discovery-read';
import { homeCopy } from '@/src/lib/i18n';
import { YeedoyLogo } from '@/src/ui/brand/yeedoy-logo';
import { BusinessTile } from '@/src/ui/components/business-tile';
import { AppSectionHeader } from '@/src/ui/components/app-section-header';
import { ThemeToggle } from '@/src/ui/components/theme-toggle';

export const revalidate = 60;

export const metadata: Metadata = {
  title: 'Yeedoy — Şehrinin Menüsünü Keşfet',
  description: 'Yeedoy ile yakınındaki restoranları, kafeleri ve menüleri keşfet. Gerçek kullanıcı yorumları ve güncel fiyatlar.',
};

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
];

type HomePageProps = {
  searchParams: Promise<{ q?: string; city?: string; category?: string; page?: string }>;
};

export default async function HomePage({ searchParams }: HomePageProps) {
  const params = await searchParams;
  const q = params.q?.trim() ?? '';
  const city = params.city?.trim() ?? '';
  const category = params.category?.trim() ?? '';
  const page = Math.max(1, parseInt(params.page ?? '1', 10));
  const hasFilters = Boolean(q || city || category);

  const [{ data: businesses, count, totalPages }, topBusinesses, supabase] = await Promise.all([
    discoverBusinesses({ q, city, category, page, pageSize: 12 }),
    getTopBusinesses(6),
    createSupabaseServerClient(),
  ]);

  // Try to get business count for social proof
  let totalBizCount = 0;
  try {
    const { count: c } = await (supabase as any)
      .from('businesses')
      .select('id', { count: 'exact', head: true })
      .eq('is_active', true) as { count: number | null };
    totalBizCount = c ?? 0;
  } catch { /* no-op */ }

  const featured = topBusinesses
    .filter((biz) => !businesses.some((item) => item.id === biz.id))
    .slice(0, 4);

  function buildHref(overrides: Partial<{ q: string; city: string; category: string; page: number }>) {
    const sp = new URLSearchParams();
    const merged = { q, city, category, page, ...overrides };
    if (merged.q) sp.set('q', merged.q);
    if (merged.city) sp.set('city', merged.city);
    if (merged.category) sp.set('category', merged.category);
    if (merged.page > 1) sp.set('page', String(merged.page));
    const qs = sp.toString();
    return `/${qs ? `?${qs}` : ''}`;
  }

  function catHref(cat: string) {
    const sp = new URLSearchParams();
    if (cat !== category) sp.set('category', cat);
    if (city) sp.set('city', city);
    const qs = sp.toString();
    return `/${qs ? `?${qs}` : ''}`;
  }

  return (
    <main className="min-h-screen bg-bg text-text">

      {/* ── Navbar ─────────────────────────────────────────────────────────── */}
      <header className="sticky top-0 z-20 border-b border-border bg-card/95 backdrop-blur">
        <div className="mx-auto flex min-h-16 w-full max-w-5xl items-center justify-between gap-3 px-4">
          <Link href="/" aria-label="Yeedoy ana sayfa" className="inline-flex min-h-11 items-center">
            <YeedoyLogo size={34} />
          </Link>
          <nav className="flex items-center gap-1.5 text-sm font-[800]">
            <Link href="/discover"
              className="hidden min-h-11 items-center rounded-full px-3 text-textStrong transition-colors hover:bg-cardAlt sm:inline-flex">
              {homeCopy.nav.discover}
            </Link>
            <Link href="/top"
              className="hidden min-h-11 items-center rounded-full px-3 text-textStrong transition-colors hover:bg-cardAlt sm:inline-flex">
              {homeCopy.nav.top}
            </Link>
            <ThemeToggle />
            <Link href="/login"
              className="inline-flex min-h-11 items-center rounded-full border border-border bg-cardAlt px-4 text-textStrong transition-all hover:border-primary/35 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary/30">
              {homeCopy.nav.panel}
            </Link>
          </nav>
        </div>
      </header>

      {/* ── Hero ───────────────────────────────────────────────────────────── */}
      <section className="relative overflow-hidden border-b border-border">
        {/* Background gradient */}
        <div className="absolute inset-0 -z-10"
          style={{ background: 'radial-gradient(ellipse at 20% 0%, rgba(127,29,29,0.10) 0%, transparent 55%), radial-gradient(ellipse at 80% 100%, rgba(220,38,38,0.06) 0%, transparent 55%), var(--yd-color-card-alt)' }} />

        <div className="mx-auto max-w-5xl px-4 pb-8 pt-10 sm:pb-12 sm:pt-14">
          {/* Kicker */}
          <div className="mb-4 inline-flex items-center gap-2 rounded-full border border-primary/20 bg-[var(--yd-color-primary-soft)] px-3 py-1">
            <span className="h-1.5 w-1.5 rounded-full bg-primary" />
            <span className="text-xs font-[900] uppercase tracking-wide text-primary">
              Türkiye&apos;nin menü platformu
            </span>
          </div>

          <div className="flex flex-col gap-8 lg:flex-row lg:items-end lg:justify-between">
            <div className="max-w-2xl">
              <h1 className="font-display text-4xl font-[900] leading-[1.05] text-textStrong sm:text-5xl lg:text-6xl">
                {homeCopy.hero.title}
              </h1>
              <p className="mt-4 max-w-xl text-base leading-relaxed text-muted sm:text-lg">
                {homeCopy.hero.body}
              </p>

              {/* Social proof */}
              {totalBizCount > 0 && (
                <div className="mt-5 flex flex-wrap items-center gap-4">
                  <div className="flex items-center gap-2">
                    <span className="text-2xl font-[900] text-textStrong">{totalBizCount.toLocaleString('tr-TR')}+</span>
                    <span className="text-sm text-muted">işletme</span>
                  </div>
                  <div className="h-4 w-px bg-border" />
                  <div className="flex items-center gap-2">
                    <svg viewBox="0 0 24 24" className="h-5 w-5 fill-amber-400" aria-hidden="true"><polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"/></svg>
                    <span className="text-sm font-[800] text-textStrong">Gerçek kullanıcı yorumları</span>
                  </div>
                  <div className="h-4 w-px bg-border" />
                  <div className="flex items-center gap-2">
                    <svg viewBox="0 0 24 24" className="h-5 w-5 fill-none stroke-current text-success" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true"><path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"/><polyline points="22 4 12 14.01 9 11.01"/></svg>
                    <span className="text-sm font-[800] text-textStrong">Güncel fiyatlar</span>
                  </div>
                </div>
              )}
            </div>

            {/* CTA buttons */}
            <div className="flex shrink-0 flex-col gap-2 sm:flex-row lg:flex-col">
              <Link href="/discover"
                className="inline-flex min-h-[52px] items-center justify-center gap-2 rounded-2xl px-6 text-base font-[900] text-white transition-all hover:-translate-y-px hover:brightness-105 active:scale-[0.97] focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary/30"
                style={{ background: 'var(--yd-gradient-primary)', boxShadow: 'var(--yd-shadow-primary-lg)' }}>
                <SearchIcon />
                Keşfetmeye Başla
              </Link>
              <Link href="/suggest"
                className="inline-flex min-h-[52px] items-center justify-center rounded-2xl border border-border bg-card px-6 text-base font-[900] text-textStrong transition-all hover:border-primary/35 hover:-translate-y-px focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary/30">
                {homeCopy.hero.suggest}
              </Link>
            </div>
          </div>

          {/* Search form */}
          <form method="GET" action="/" className="mt-8 grid gap-2 sm:grid-cols-[1fr_160px_auto]">
            <div className="relative">
              <span className="pointer-events-none absolute inset-y-0 left-3.5 flex items-center text-muted">
                <SearchIcon size={16} />
              </span>
              <input type="text" name="q" defaultValue={q} placeholder={homeCopy.filters.search}
                className="w-full rounded-2xl border border-border bg-card py-3 pl-9 pr-4 text-sm text-textStrong placeholder:text-muted focus:outline-none focus:ring-2 focus:ring-primary/30" />
            </div>
            <input type="text" name="city" defaultValue={city} placeholder={homeCopy.filters.city}
              className="rounded-2xl border border-border bg-card px-4 py-3 text-sm text-textStrong placeholder:text-muted focus:outline-none focus:ring-2 focus:ring-primary/30" />
            <button type="submit"
              className="min-h-[52px] rounded-2xl px-6 text-sm font-[900] text-white transition-all hover:-translate-y-px hover:brightness-105 active:scale-[0.97] focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary/30"
              style={{ background: 'var(--yd-gradient-primary)', boxShadow: 'var(--yd-shadow-primary)' }}>
              {homeCopy.filters.submit}
            </button>
          </form>

          {/* Category quick filters */}
          <div className="mt-4 flex gap-2 overflow-x-auto pb-1 [-ms-overflow-style:none] [scrollbar-width:none] [&::-webkit-scrollbar]:hidden">
            {CATEGORIES.map((cat) => (
              <Link key={cat.id} href={catHref(cat.id)}
                className={`inline-flex shrink-0 min-h-[40px] items-center rounded-full border px-3.5 py-1 text-sm font-[800] whitespace-nowrap transition-all duration-[150ms] focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary/30 ${category === cat.id ? 'bg-[var(--yd-color-primary-soft)] border-primary/40 text-primary' : 'bg-card border-border text-textStrong hover:border-primary/30'}`}>
                {cat.label}
              </Link>
            ))}
            {hasFilters && (
              <Link href="/"
                className="inline-flex shrink-0 min-h-[40px] items-center rounded-full border border-dashed border-border px-3.5 py-1 text-sm text-muted transition-colors hover:text-textStrong">
                Temizle ×
              </Link>
            )}
          </div>
        </div>
      </section>

      {/* ── Body ───────────────────────────────────────────────────────────── */}
      <div className="mx-auto grid w-full max-w-5xl gap-8 px-4 py-7 lg:grid-cols-[1fr_320px]">

        {/* Main list */}
        <section>
          <AppSectionHeader
            title={category ? `${category} İşletmeleri` : homeCopy.sections.businesses}
            subtitle={count > 0 ? homeCopy.results.count(count) : homeCopy.results.empty}
            className="mb-5"
          />

          {businesses.length > 0 ? (
            <div className="flex flex-col gap-3">
              {businesses.map((business) => (
                <BusinessTile key={business.id}
                  slug={business.slug ?? business.id}
                  name={business.name}
                  category={business.category}
                  subtitle={[business.city, business.description].filter(Boolean).join(' · ')}
                  isVerified={business.is_verified} />
              ))}
            </div>
          ) : (
            <div className="rounded-[20px] border border-border bg-card px-5 py-14 text-center">
              <p className="font-[900] text-textStrong">{homeCopy.empty.title}</p>
              <p className="mt-2 text-sm text-muted">{homeCopy.empty.body}</p>
              {hasFilters && (
                <Link href="/" className="mt-4 inline-block text-sm font-[700] text-primary hover:underline">
                  Filtreleri temizle →
                </Link>
              )}
            </div>
          )}

          {totalPages > 1 && (
            <div className="mt-6 flex items-center justify-center gap-2">
              {page > 1 && (
                <Link href={buildHref({ page: page - 1 })}
                  className="inline-flex min-h-11 items-center rounded-2xl border border-border bg-card px-4 text-sm font-[800] text-textStrong transition-colors hover:border-primary/40 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary/30">
                  {homeCopy.pagination.previous}
                </Link>
              )}
              <span className="px-2 text-sm font-[800] text-muted">{page} / {totalPages}</span>
              {page < totalPages && (
                <Link href={buildHref({ page: page + 1 })}
                  className="inline-flex min-h-11 items-center rounded-2xl border border-border bg-card px-4 text-sm font-[800] text-textStrong transition-colors hover:border-primary/40 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary/30">
                  {homeCopy.pagination.next}
                </Link>
              )}
            </div>
          )}
        </section>

        {/* Sidebar */}
        <aside className="space-y-5 lg:sticky lg:top-24 lg:self-start">
          {/* Top businesses */}
          <section>
            <AppSectionHeader title={homeCopy.sections.top} className="mb-4" />
            <div className="space-y-3">
              {(featured.length > 0 ? featured : topBusinesses.slice(0, 4)).map((business) => (
                <BusinessTile key={business.id}
                  slug={business.slug ?? business.id}
                  name={business.name}
                  category={business.category}
                  subtitle={business.city}
                  isVerified={business.is_verified}
                  badgeText={homeCopy.badges.popular}
                  className="p-2.5" />
              ))}
            </div>
            <Link href="/top" className="mt-3 inline-flex text-sm font-[700] text-primary hover:underline">
              Tüm listeye bak →
            </Link>
          </section>

          {/* Panel CTA */}
          <section className="rounded-[20px] border border-border bg-cardAlt p-5 shadow-yd1">
            <div className="mb-1 flex h-10 w-10 items-center justify-center rounded-xl bg-[var(--yd-color-primary-soft)]">
              <svg viewBox="0 0 24 24" className="h-5 w-5 text-primary fill-none stroke-current" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true"><rect x="2" y="3" width="20" height="14" rx="2"/><line x1="8" y1="21" x2="16" y2="21"/><line x1="12" y1="17" x2="12" y2="21"/></svg>
            </div>
            <p className="mt-3 font-[900] text-textStrong">{homeCopy.panel.title}</p>
            <p className="mt-1.5 text-sm leading-6 text-muted">{homeCopy.panel.body}</p>
            <div className="mt-4 flex flex-col gap-2">
              <Link href="/login"
                className="inline-flex min-h-11 items-center justify-center rounded-2xl px-4 text-sm font-[900] text-white transition-all hover:-translate-y-px hover:brightness-105 active:scale-[0.97] focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary/30"
                style={{ background: 'var(--yd-gradient-primary)', boxShadow: 'var(--yd-shadow-primary)' }}>
                {homeCopy.panel.login}
              </Link>
              <Link href="/owner/onboarding"
                className="inline-flex min-h-11 items-center justify-center rounded-2xl border border-border bg-card px-4 text-sm font-[900] text-textStrong transition-colors hover:border-primary/40 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary/30">
                {homeCopy.panel.owner}
              </Link>
            </div>
          </section>
        </aside>
      </div>
    </main>
  );
}

function SearchIcon({ size = 18 }: { size?: number }) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
      <circle cx="11" cy="11" r="8"/>
      <line x1="21" y1="21" x2="16.65" y2="16.65"/>
    </svg>
  );
}
