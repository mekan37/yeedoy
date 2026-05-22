import Image from 'next/image';
import Link from 'next/link';
import { clsx } from 'clsx';
import { buildMenuImageUrl } from '@/src/lib/medya-adresi';
import { Badge, ButtonLink, Card, EmptyState, SectionHeader, Skeleton } from '@/src/ui/acik/ortak';
import { FavoriteButton } from '@/src/ui/acik/eylem-istemcisi';
import { Icon } from '@/src/ui/acik/simgeler';
import type { AcikIsletmeKarti } from '@/src/ui/acik/tipler';

export const MARKETPLACE_CATEGORIES = [
  { id: '', label: 'Tümü', icon: '🍽' },
  { id: 'Restoran', label: 'Restoran', icon: '🍽' },
  { id: 'Kafe', label: 'Kafe', icon: '☕' },
  { id: 'Fast Food', label: 'Fast Food', icon: '🍔' },
  { id: 'Dönerci', label: 'Döner', icon: '🥙' },
  { id: 'Pizza', label: 'Pizza', icon: '🍕' },
  { id: 'Burger', label: 'Burger', icon: '🍔' },
  { id: 'Pide / Lahmacun', label: 'Pide', icon: '🥖' },
  { id: 'Pastane', label: 'Pastane', icon: '🍰' },
  { id: 'Kahvaltı', label: 'Kahvaltı', icon: '🍳' },
];

export function HeroSearchSection({ q = '', city = '', action = '/kesif' }: { q?: string; city?: string; action?: string }) {
  return (
    <section
      className="relative overflow-hidden text-white"
      style={{
        background:
          'linear-gradient(135deg, var(--yd-color-primary-deep) 0%, var(--yd-color-primary) 48%, var(--yd-color-primary-strong) 100%)',
      }}
    >
      <div className="absolute inset-0 bg-[radial-gradient(circle_at_20%_15%,rgba(255,255,255,0.16),transparent_30%),radial-gradient(circle_at_82%_78%,rgba(255,255,255,0.12),transparent_34%)]" />
      <div className="relative mx-auto flex min-h-[500px] max-w-7xl flex-col items-center justify-center px-4 py-16 text-center sm:px-6 sm:py-24 lg:px-8">
        <div className="landing-hero-copy w-full">
          <h1 className="mx-auto max-w-4xl text-4xl font-[900] leading-[1.05] text-white sm:text-5xl lg:text-6xl">
            Yakınındaki lezzetleri keşfet
          </h1>
          <p className="mx-auto mt-6 max-w-2xl text-lg leading-8 text-white/90 sm:text-xl">
            Restoranları, kafeleri ve menüleri keşfet. Yorumları oku, fiyatları karşılaştır, QR menüye tek dokunuşla ulaş.
          </p>
          <SearchBar q={q} city={city} action={action} className="mx-auto mt-9" />
          <div className="mt-8 flex flex-wrap justify-center gap-4 text-sm font-[800] text-white/92">
            <span className="inline-flex items-center gap-2"><span className="h-2 w-2 rounded-full bg-white" /> Doğrulanmış işletmeler</span>
            <span className="inline-flex items-center gap-2"><span className="h-2 w-2 rounded-full bg-white" /> Güncel fiyatlar</span>
            <span className="inline-flex items-center gap-2"><span className="h-2 w-2 rounded-full bg-white" /> Public QR menü</span>
          </div>
        </div>
      </div>
    </section>
  );
}

export function SearchBar({ q = '', city = '', action = '/kesif', className }: { q?: string; city?: string; action?: string; className?: string }) {
  return (
    <form method="GET" action={action} className={clsx('grid w-full max-w-4xl gap-2 rounded-[32px] bg-white p-2 shadow-[0_24px_60px_rgba(15,23,42,0.24)] sm:grid-cols-[1fr_1fr_auto]', className)}>
      <label className="relative block">
        <span className="pointer-events-none absolute inset-y-0 left-4 flex items-center text-muted"><Icon name="search" size={19} /></span>
        <input name="q" defaultValue={q} placeholder="İşletme, mutfak veya ürün" className="min-h-[52px] w-full rounded-full border-0 bg-bg py-3 pl-12 pr-4 text-sm font-[700] text-textStrong placeholder:text-muted focus:outline-none focus:ring-2 focus:ring-primary/30" />
      </label>
      <LocationSearchInput city={city} />
      <button type="submit" className="min-h-[52px] rounded-full px-8 text-sm font-[900] text-white shadow-[var(--yd-shadow-primary)] hover:-translate-y-px hover:brightness-105" style={{ background: 'var(--yd-gradient-primary)' }}>
        Ara
      </button>
    </form>
  );
}

export function LocationSearchInput({ city = '' }: { city?: string }) {
  return (
    <label className="relative block">
      <span className="pointer-events-none absolute inset-y-0 left-4 flex items-center text-muted"><Icon name="pin" size={19} /></span>
      <input name="city" defaultValue={city} placeholder="Konum" className="min-h-[52px] w-full rounded-full border-0 bg-bg py-3 pl-12 pr-4 text-sm font-[700] text-textStrong placeholder:text-muted focus:outline-none focus:ring-2 focus:ring-primary/30" />
    </label>
  );
}

export function CategoryFilterChips({ selected = '', city = '', q = '', basePath = '/kesif' }: { selected?: string; city?: string; q?: string; basePath?: string }) {
  function href(category: string) {
    const sp = new URLSearchParams();
    if (q) sp.set('q', q);
    if (city) sp.set('city', city);
    if (category) sp.set('category', category);
    const qs = sp.toString();
    return `${basePath}${qs ? `?${qs}` : ''}`;
  }

  return (
    <div className="flex gap-2 overflow-x-auto py-4 [-ms-overflow-style:none] [scrollbar-width:none] [&::-webkit-scrollbar]:hidden">
      {MARKETPLACE_CATEGORIES.map((category) => {
        const active = selected === category.id || (!selected && !category.id);
        return (
          <Link
            key={category.label}
            href={href(category.id)}
            className={clsx(
              'inline-flex min-h-[76px] min-w-[92px] shrink-0 flex-col items-center justify-center gap-2 rounded-xl px-4 text-sm font-[900] focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary/30',
              active ? 'bg-primary text-white shadow-[var(--yd-shadow-primary)]' : 'bg-bg text-textStrong hover:bg-cardAlt',
            )}
          >
            <span className="text-xl" aria-hidden="true">{category.icon}</span>
            {category.label}
          </Link>
        );
      })}
    </div>
  );
}

export function BusinessGrid({ businesses, emptyHref = '/kesif' }: { businesses: AcikIsletmeKarti[]; emptyHref?: string }) {
  if (businesses.length === 0) {
    return <EmptyDiscoveryState href={emptyHref} />;
  }
  return (
    <div className="grid gap-6 sm:grid-cols-2 lg:grid-cols-3">
      {businesses.map((business) => <BusinessCard key={business.id} business={business} />)}
    </div>
  );
}

export function BusinessCard({ business }: { business: AcikIsletmeKarti }) {
  const slug = business.slug || business.publicSlug || business.id;
  const cover = buildMenuImageUrl(business.coverUrl || business.logoUrl, { width: 700, quality: 78 });
  return (
    <Card href={`/isletme/${slug}`} className="group cursor-pointer overflow-hidden rounded-2xl bg-card shadow-sm transition-all duration-300 hover:-translate-y-1 hover:shadow-xl">
      <div className="relative h-48 overflow-hidden bg-cardAlt">
        {cover ? (
          <Image src={cover} alt={business.name} fill sizes="(min-width: 1024px) 33vw, (min-width: 640px) 50vw, 100vw" className="object-cover transition-transform duration-300 group-hover:scale-105" />
        ) : (
          <div className="flex h-full items-center justify-center text-muted"><Icon name="image" size={28} /></div>
        )}
        <div className="absolute left-3 top-3 flex flex-wrap gap-2">
          {business.isVerified ? <Badge tone="success">Onaylı</Badge> : null}
          {business.isOpenNow != null ? <Badge tone={business.isOpenNow ? 'success' : 'neutral'}>{business.isOpenNow ? 'Açık' : 'Kapalı'}</Badge> : null}
        </div>
        <div className="absolute right-3 top-3">
          <FavoriteButton label="Favori" className="min-h-10 rounded-full bg-card/95 px-3 backdrop-blur" />
        </div>
      </div>
      <div className="p-4">
        <div className="flex items-start justify-between gap-3">
          <div className="min-w-0">
            <h3 className="truncate text-lg font-[900] text-textStrong group-hover:text-primary">{business.name}</h3>
            <p className="mt-1 truncate text-sm text-muted">{[business.category, business.district || business.city].filter(Boolean).join(' · ')}</p>
          </div>
          {business.avgRating ? (
            <span className={`inline-flex shrink-0 items-center gap-1 rounded-lg px-2 py-1 text-xs font-[900] text-white ${
              business.avgRating >= 4.5 ? 'bg-success' :
              business.avgRating >= 4.0 ? 'bg-[#22c55e]/80' :
              business.avgRating >= 3.5 ? 'bg-warning' : 'bg-danger/80'
            }`}>
              <Icon name="star" size={13} />
              {business.avgRating.toFixed(1)}
            </span>
          ) : null}
        </div>
        <div className="mt-4 flex flex-wrap items-center gap-4 text-sm text-muted">
          <span className="inline-flex items-center rounded-full border border-border bg-bg px-2 py-0.5 text-xs font-[900] text-textStrong">
            {business.medianPriceCents ? formatPriceLevel(business.medianPriceCents) : '₺₺'}
          </span>
          <span className="inline-flex items-center gap-1"><Icon name="clock" size={15} /> 20-35 dk</span>
          {business.distanceKm ? <span className="inline-flex items-center gap-1"><Icon name="pin" size={15} /> {business.distanceKm.toFixed(1)} km</span> : <span className="inline-flex items-center gap-1"><Icon name="pin" size={15} /> Yakında</span>}
        </div>
        <div className="mt-4 flex items-center justify-between border-t border-border pt-3">
          <span className="text-xs text-muted">{business.reviewCount ? `${business.reviewCount.toLocaleString('tr-TR')} yorum` : 'Yeni işletme'}</span>
          <span className="inline-flex items-center gap-1 text-sm font-[900] text-primary">
            Menüyü Gör <Icon name="chevronRight" size={14} />
          </span>
        </div>
      </div>
    </Card>
  );
}

export function BusinessCardSkeleton() {
  return (
    <Card className="overflow-hidden">
      <Skeleton className="aspect-[16/10] rounded-none" />
      <div className="space-y-3 p-4">
        <Skeleton className="h-5 w-2/3" />
        <Skeleton className="h-4 w-1/2" />
        <div className="flex gap-2"><Skeleton className="h-7 w-20 rounded-full" /><Skeleton className="h-7 w-24 rounded-full" /></div>
      </div>
    </Card>
  );
}

export function EmptyDiscoveryState({ href = '/kesif' }: { href?: string }) {
  return (
    <EmptyState
      variant="search"
      title="Bu aramayla eşleşen işletme yok"
      body="Kategori, şehir veya arama terimini değiştirerek tekrar deneyin."
      actionHref={href}
      actionLabel="Filtreleri temizle"
    />
  );
}

export function LoadMoreButton({ href }: { href: string }) {
  return <ButtonLink href={href} variant="secondary" className="min-h-11">Daha fazla göster</ButtonLink>;
}

export function DiscoveryResults({
  businesses,
  count,
  q,
  city,
  category,
  page,
  totalPages,
  basePath = '/kesif',
}: {
  businesses: AcikIsletmeKarti[];
  count: number;
  q?: string;
  city?: string;
  category?: string;
  page: number;
  totalPages: number;
  basePath?: string;
}) {
  function pageHref(nextPage: number) {
    const sp = new URLSearchParams();
    if (q) sp.set('q', q);
    if (city) sp.set('city', city);
    if (category) sp.set('category', category);
    if (nextPage > 1) sp.set('page', String(nextPage));
    const qs = sp.toString();
    return `${basePath}${qs ? `?${qs}` : ''}`;
  }

  return (
    <section>
      <SectionHeader
        title={category ? `${category} işletmeleri` : 'İşletme keşfi'}
        subtitle={count > 0 ? `${count.toLocaleString('tr-TR')} sonuç` : 'Sonuç bulunamadı'}
        className="mb-5"
      />
      <BusinessGrid businesses={businesses} emptyHref={basePath} />
      {totalPages > 1 ? (
        <div className="mt-7 flex items-center justify-center gap-3">
          {page > 1 ? <LoadMoreButton href={pageHref(page - 1)} /> : null}
          <span className="text-sm font-[900] text-muted">{page} / {totalPages}</span>
          {page < totalPages ? <LoadMoreButton href={pageHref(page + 1)} /> : null}
        </div>
      ) : null}
    </section>
  );
}

function formatPriceLevel(cents: number) {
  if (cents < 20000) return '₺';
  if (cents < 45000) return '₺₺';
  return '₺₺₺';
}

export type FiyatSinyalItem = {
  business_id?: string | null;
  business_name?: string | null;
  slug?: string | null;
  verified_count?: number | null;
  city?: string | null;
  category?: string | null;
};

export function FiyatSinyalleri({ signals }: { signals: FiyatSinyalItem[] }) {
  if (!signals || signals.length === 0) return null;

  return (
    <section>
      <SectionHeader eyebrow="Fiyat şeffaflığı" title="🔍 Son Doğrulanan Fiyatlar" className="mb-5" />
      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
        {signals.map((signal, index) => {
          const slug = signal.slug || signal.business_id;
          const href = slug ? `/isletme/${slug}` : '#';
          return (
            <Card key={signal.business_id ?? index} href={href} className="p-4">
              <p className="truncate text-sm font-[900] text-textStrong">{signal.business_name ?? 'İşletme'}</p>
              <p className="mt-1 truncate text-xs text-muted">
                {[signal.category, signal.city].filter(Boolean).join(' · ')}
              </p>
              {signal.verified_count ? (
                <p className="mt-3 inline-flex items-center gap-1 text-xs font-[900] text-success">
                  <span className="h-1.5 w-1.5 rounded-full bg-success" aria-hidden="true" />
                  {signal.verified_count} doğrulanmış fiyat
                </p>
              ) : null}
            </Card>
          );
        })}
      </div>
    </section>
  );
}

export type BugunSpecialItem = {
  id?: string | null;
  item_name?: string | null;
  business_name?: string | null;
  business_slug?: string | null;
  business_id?: string | null;
  price_cents?: number | null;
  currency?: string | null;
};

// ─── Fiyat Anomalisi ────────────────────────────────────────────────────────

export type FiyatAnomaliItem = {
  business_id?: string | null;
  business_name?: string | null;
  slug?: string | null;
  city?: string | null;
  category?: string | null;
  median_price_cents?: number | null;
  city_avg_price_cents?: number | null;
  diff_pct?: number | null;
};

export function FiyatAnomali({ items }: { items: FiyatAnomaliItem[] }) {
  if (!items || items.length === 0) return null;

  function fiyatStr(cents?: number | null) {
    if (!cents) return null;
    return `₺${(cents / 100).toLocaleString('tr-TR', { minimumFractionDigits: 0, maximumFractionDigits: 0 })}`;
  }

  function diffLabel(pct?: number | null) {
    if (pct == null) return null;
    const abs = Math.abs(Math.round(pct * 100));
    if (pct < -0.1) return { text: `%${abs} daha uygun`, tone: 'success' as const };
    if (pct > 0.15) return { text: `%${abs} daha pahalı`, tone: 'warning' as const };
    return null;
  }

  return (
    <section>
      <SectionHeader eyebrow="Fiyat sinyali" title="📊 Bölge Ortalamasına Göre" className="mb-5" />
      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
        {items.map((item, idx) => {
          const slug = item.slug || item.business_id;
          const href = slug ? `/isletme/${slug}` : '#';
          const diff = diffLabel(item.diff_pct);
          return (
            <Card key={item.business_id ?? idx} href={href} className="p-4">
              <p className="truncate text-sm font-[900] text-textStrong">{item.business_name ?? 'İşletme'}</p>
              <p className="mt-0.5 truncate text-xs text-muted">
                {[item.category, item.city].filter(Boolean).join(' · ')}
              </p>
              {fiyatStr(item.median_price_cents) && (
                <p className="mt-3 text-base font-[900] text-textStrong">{fiyatStr(item.median_price_cents)}</p>
              )}
              {diff ? (
                <p className={`mt-1 text-xs font-[900] ${diff.tone === 'success' ? 'text-success' : 'text-warning'}`}>
                  {diff.text}
                </p>
              ) : null}
            </Card>
          );
        })}
      </div>
    </section>
  );
}

// ─── Bölgesel Fiyat Endeksi ──────────────────────────────────────────────────

export type BolgeFiyatItem = {
  city?: string | null;
  avg_price_cents?: number | null;
  business_count?: number | null;
  category_sample?: string | null;
};

export function BolgeselFiyatEndeksi({ cities }: { cities: BolgeFiyatItem[] }) {
  if (!cities || cities.length === 0) return null;

  function fiyatStr(cents?: number | null) {
    if (!cents) return '—';
    return `₺${(cents / 100).toLocaleString('tr-TR', { minimumFractionDigits: 0, maximumFractionDigits: 0 })}`;
  }

  function priceLevel(cents?: number | null) {
    if (!cents) return '₺';
    if (cents < 15000) return '₺';
    if (cents < 35000) return '₺₺';
    return '₺₺₺';
  }

  return (
    <section>
      <SectionHeader eyebrow="Bölgesel karşılaştırma" title="🗺 Şehre Göre Ortalama Fiyat" className="mb-5" />
      <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-3">
        {cities.map((city, idx) => (
          <Card
            key={city.city ?? idx}
            href={`/kesif?city=${encodeURIComponent(city.city ?? '')}`}
            className="flex items-center gap-4 p-4"
          >
            <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-xl bg-[var(--yd-color-primary-soft)] text-lg font-[900] text-primary">
              {priceLevel(city.avg_price_cents)}
            </div>
            <div className="min-w-0 flex-1">
              <p className="truncate text-sm font-[900] text-textStrong">{city.city ?? 'Şehir'}</p>
              <p className="text-xs text-muted">
                Ort. {fiyatStr(city.avg_price_cents)}
                {city.business_count ? ` · ${city.business_count} işletme` : ''}
              </p>
            </div>
          </Card>
        ))}
      </div>
    </section>
  );
}

// ─── Kampanya Hikayeleri ─────────────────────────────────────────────────────

export type KampanyaItem = {
  id?: string | null;
  business_id?: string | null;
  business_name?: string | null;
  business_slug?: string | null;
  title?: string | null;
  description?: string | null;
  discount_pct?: number | null;
  valid_until?: string | null;
};

export function KampanyaHikayeleri({ campaigns }: { campaigns: KampanyaItem[] }) {
  if (!campaigns || campaigns.length === 0) return null;

  function bitisTarih(until?: string | null) {
    if (!until) return null;
    try {
      return new Date(until).toLocaleDateString('tr-TR', { day: 'numeric', month: 'short' });
    } catch { return null; }
  }

  return (
    <section>
      <SectionHeader eyebrow="Aktif kampanyalar" title="🎯 Bu Hafta Fırsatlar" className="mb-5" />
      <div className="flex gap-3 overflow-x-auto pb-2 [-ms-overflow-style:none] [scrollbar-width:none] [&::-webkit-scrollbar]:hidden">
        {campaigns.map((camp, idx) => {
          const slug = camp.business_slug || camp.business_id;
          const href = slug ? `/isletme/${slug}` : '#';
          const bitisTarihStr = bitisTarih(camp.valid_until);
          return (
            <Link
              key={camp.id ?? idx}
              href={href}
              className="shrink-0 w-56 rounded-2xl p-4 block transition-all hover:-translate-y-0.5 hover:shadow-yd2 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary/30"
              style={{ background: 'linear-gradient(135deg, #5c1515 0%, #7f1d1d 100%)' }}
            >
              {camp.discount_pct ? (
                <p className="mb-2 inline-flex items-center rounded-lg bg-white/20 px-2 py-1 text-[11px] font-[900] text-white">
                  %{camp.discount_pct} İndirim
                </p>
              ) : null}
              <p className="text-sm font-[900] leading-snug text-white">{camp.title ?? 'Kampanya'}</p>
              <p className="mt-1 text-xs text-white/75">{camp.business_name}</p>
              {bitisTarihStr && (
                <p className="mt-3 text-[11px] text-white/60">{bitisTarihStr} tarihine kadar</p>
              )}
            </Link>
          );
        })}
      </div>
    </section>
  );
}

export function BugunSpecials({ specials }: { specials: BugunSpecialItem[] }) {
  if (!specials || specials.length === 0) return null;

  function formatFiyat(cents?: number | null, currency?: string | null) {
    if (!cents) return null;
    const symbol = currency === 'TRY' || !currency ? '₺' : currency;
    return `${symbol}${(cents / 100).toLocaleString('tr-TR', { minimumFractionDigits: 0, maximumFractionDigits: 2 })}`;
  }

  return (
    <section>
      <SectionHeader eyebrow="Bugün öne çıkan" title="✨ Bugünün Spesiyali" className="mb-5" />
      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
        {specials.map((special, index) => {
          const slug = special.business_slug || special.business_id;
          const href = slug ? `/isletme/${slug}` : '#';
          const price = formatFiyat(special.price_cents, special.currency);
          return (
            <Card key={special.id ?? index} href={href} className="p-4">
              <p className="truncate text-sm font-[900] text-textStrong">{special.item_name ?? 'Spesiyel'}</p>
              <p className="mt-1 truncate text-xs text-muted">{special.business_name}</p>
              {price ? (
                <p className="mt-2 text-sm font-[900] text-primary">{price}</p>
              ) : null}
            </Card>
          );
        })}
      </div>
    </section>
  );
}


