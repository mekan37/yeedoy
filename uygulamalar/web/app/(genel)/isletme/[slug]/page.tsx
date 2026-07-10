import type { Metadata } from 'next';
import { notFound } from 'next/navigation';
import Image from 'next/image';
import Link from 'next/link';
import { PublicShell } from '@/src/ui/acik/yerlesim';
import { buildMenuImageUrl } from '@/src/lib/medya-adresi';
import {
  getMarketplaceBusinessBySlug,
  getBusinessReviews,
  getMarketplaceBusinesses,
} from '@/src/lib/veri/pazar-okuma';
import { getPublicMenuPageData } from '@/src/lib/acik-menu-sayfasi';
import { appConfig } from '@/src/lib/ayarlar';
import type { AcikMenuUrunKarti } from '@/src/ui/acik/tipler';
import { FavoriteButton, ShareButton } from '@/src/ui/acik/eylem-istemcisi';
import { Icon } from '@/src/ui/acik/simgeler';
import { FotoGalerisiTetik, type GaleriPhoto } from '@/src/ui/acik/foto-galerisi-modal';
import { createSupabasePublicClient } from '@/src/lib/taban/acik';
import {
  IsletmeDetayTablari,
  type YorumDetay,
  type AltPuanOrt,
} from './isletme-detay-tablari';

export const revalidate = 300;

export async function generateStaticParams(): Promise<Array<{ slug: string }>> {
  try {
    const supabase = createSupabasePublicClient();
    const { data } = await (supabase as any)
      .from('businesses')
      .select('slug')
      .eq('is_active', true)
      .not('slug', 'is', null)
      .order('created_at', { ascending: false })
      .limit(100) as { data: Array<{ slug: string }> | null };
    if (!data) return [];
    return data.map((row) => ({ slug: row.slug }));
  } catch {
    return [];
  }
}

type Props = { params: Promise<{ slug: string }> };

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { slug } = await params;
  const business = await getMarketplaceBusinessBySlug(slug);
  if (!business) return { title: 'İşletme | Yeedoy' };
  const siteUrl = appConfig.siteUrl().replace(/\/$/, '');
  const canonical = `${siteUrl}/isletme/${business.slug}`;
  const title = `${business.name}${business.city ? ` | ${business.city}` : ''} | Yeedoy`;
  const description =
    business.description ??
    `${business.name} menüsü, yorumları, adresi ve fiyat bilgileri.`;
  return {
    title,
    description,
    alternates: { canonical },
    openGraph: {
      title,
      description,
      url: canonical,
      images: [
        {
          url:
            business.coverUrl ??
            `${siteUrl}/sunucu/acik-grafik?title=${encodeURIComponent(business.name)}`,
          width: 1200,
          height: 630,
          alt: business.name,
        },
      ],
    },
  };
}

function formatPrice(cents?: number | null) {
  if (!cents) return null;
  return `₺${(cents / 100).toLocaleString('tr-TR', { minimumFractionDigits: 0, maximumFractionDigits: 0 })}`;
}

function priceLevelSymbol(level?: string | null, medianCents?: number | null): string | null {
  if (level === 'budget') return '₺';
  if (level === 'mid') return '₺₺';
  if (level === 'premium') return '₺₺₺';
  if (medianCents) {
    if (medianCents < 20000) return '₺';
    if (medianCents < 45000) return '₺₺';
    return '₺₺₺';
  }
  return null;
}

// ── Keyword extraction (TR stopwords) ────────────────────────────────────────

const TR_STOPWORDS = new Set([
  'bir', 've', 'bu', 'de', 'da', 'ile', 'için', 'ama', 'var', 'olan',
  'gibi', 'kadar', 'daha', 'her', 'tam', 'çok', 'biz', 'siz', 'ben',
  'sen', 'hem', 'yok', 'tüm', 'iyi', 'güzel', 'harika', 'oldu', 'bile',
  'aynı', 'çok', 'çok', 'gerçekten', 'kesinlikle', 'oldukça', 'kez',
  'gidip', 'gittik', 'geldik', 'aldım', 'aldık', 'ettik', 'ettim', 'etti',
]);

function kelimeCikar(yorumlar: Array<{ content: string | null }>): Array<{ kelime: string; sayi: number }> {
  const sayaci = new Map<string, number>();
  for (const y of yorumlar) {
    if (!y.content) continue;
    const kelimeler = y.content.toLocaleLowerCase('tr-TR').match(/[a-züğışçö]{4,}/g) ?? [];
    for (const k of kelimeler) {
      if (TR_STOPWORDS.has(k)) continue;
      sayaci.set(k, (sayaci.get(k) ?? 0) + 1);
    }
  }
  return [...sayaci.entries()]
    .sort((a, b) => b[1] - a[1])
    .slice(0, 10)
    .map(([kelime, sayi]) => ({ kelime, sayi }));
}

export default async function BusinessPage({ params }: Props) {
  const { slug } = await params;
  const business = await getMarketplaceBusinessBySlug(slug);
  if (!business) notFound();

  type MealCardPublicRow = { key: string; name: string; asset_name: string };
  type ReviewStatRow = {
    rating: number;
    taste_rating: number | null;
    service_speed_rating: number | null;
    atmosphere_rating: number | null;
    price_performance_rating: number | null;
    cleanliness_rating: number | null;
  };

  type ChainInfoRow = {
    chain_id: string; chain_name: string; chain_slug: string | null;
    chain_logo_url: string | null; chain_is_verified: boolean;
    branch_label: string | null; is_template_branch: boolean; branch_count: number;
  };

  const [, menuData, checkinCount, , , mealCards, similar, detayliYorumlarRaw, reviewStatsRaw, chainInfoRaw] =
    await Promise.all([
      getBusinessReviews(business.id, 6),
      getPublicMenuPageData({ businessSlugOrId: business.slug }).catch(() => null),
      (createSupabasePublicClient() as any)
        .rpc('get_business_recent_checkins_v1', { p_business_id: business.id, p_hours: 2 })
        .then((r: any) => r?.data?.count ?? 0)
        .catch(() => 0),
      // price comparison + history — unused in new layout but kept for future
      (createSupabasePublicClient() as any)
        .rpc('get_business_price_comparison_v1', { p_business_id: business.id, p_limit: 5 })
        .then((r: any) => (r?.data as any[]) ?? [])
        .catch(() => []),
      (createSupabasePublicClient() as any)
        .rpc('get_business_price_history_v1', { p_business_id: business.id, p_months: 6 })
        .then((r: any) => (r?.data as any[]) ?? [])
        .catch(() => []),
      (createSupabasePublicClient() as any)
        .rpc('get_business_meal_card_providers_v1', { p_business_id: business.id })
        .then((r: any) => (r?.data as MealCardPublicRow[]) ?? [])
        .catch(() => [] as MealCardPublicRow[]),
      business.category
        ? getMarketplaceBusinesses({ category: business.category, pageSize: 8 })
            .then((r) => r.data.filter((b) => b.id !== business.id).slice(0, 6))
            .catch(() => [])
        : Promise.resolve([]),
      // Detaylı yorumlar (ilk 15) — FK yoktur, profil ayrı çekilir
      (createSupabasePublicClient() as any)
        .from('business_reviews')
        .select('id, rating, overall_rating, content, title, created_at, helpful_count, taste_rating, service_speed_rating, atmosphere_rating, price_performance_rating, cleanliness_rating, owner_reply, user_id')
        .eq('business_id', business.id)
        .eq('status', 'approved')
        .order('created_at', { ascending: false })
        .limit(15) as Promise<{ data: any[] | null; error: any }>,
      // İstatistik veriler (rating dağılımı + alt puan ortalamaları)
      (createSupabasePublicClient() as any)
        .from('business_reviews')
        .select('rating, taste_rating, service_speed_rating, atmosphere_rating, price_performance_rating, cleanliness_rating')
        .eq('business_id', business.id)
        .eq('status', 'approved')
        .limit(500) as Promise<{ data: ReviewStatRow[] | null; error: any }>,
      // Zincir bilgisi
      (createSupabasePublicClient() as any)
        .rpc('get_business_chain_info_v1', { p_business_id: business.id })
        .then((r: any) => (r?.data as ChainInfoRow[]) ?? [])
        .catch(() => [] as ChainInfoRow[]),
    ]);

  // Profilleri ayrı sorgula (FK constraint olmadığından join kullanılamaz)
  const reviewsBase: any[] = detayliYorumlarRaw?.data ?? [];
  let profilesMap: Record<string, { display_name: string; avatar_url: string | null }> = {};
  try {
    const userIds = [...new Set(reviewsBase.map((r) => r.user_id).filter(Boolean))] as string[];
    if (userIds.length > 0) {
      const { data: profs } = await (createSupabasePublicClient() as any)
        .from('user_profiles')
        .select('user_id, display_name, avatar_url')
        .in('user_id', userIds);
      for (const p of profs ?? []) {
        profilesMap[p.user_id] = { display_name: p.display_name, avatar_url: p.avatar_url ?? null };
      }
    }
  } catch { /* profil yoksa Anonim göster */ }
  const detayliYorumlar: YorumDetay[] = reviewsBase.map((r) => ({
    ...r,
    user_profiles: r.user_id ? (profilesMap[r.user_id] ?? null) : null,
  }));
  const reviewStats: ReviewStatRow[] = reviewStatsRaw?.data ?? [];
  const chainInfo: ChainInfoRow | null = (chainInfoRaw as ChainInfoRow[])[0] ?? null;

  // Yıldız dağılımı
  const yildizDagitimi: Record<string, number> = { '1': 0, '2': 0, '3': 0, '4': 0, '5': 0 };
  for (const s of reviewStats) {
    const k = String(Math.round(s.rating));
    if (k in yildizDagitimi) yildizDagitimi[k]!++;
  }

  // Alt puan ortalamaları — gerçek kolon isimleriyle
  const altPuanOrt: AltPuanOrt = (() => {
    const avg = (key: keyof ReviewStatRow): number | null => {
      const arr = reviewStats.filter((s) => s[key] != null);
      if (arr.length === 0) return null;
      return parseFloat((arr.reduce((sum, s) => sum + (s[key] as number), 0) / arr.length).toFixed(1));
    };
    return {
      lezzet: avg('taste_rating'),
      servis: avg('service_speed_rating'),
      temizlik: avg('cleanliness_rating'),
      fiyat: avg('price_performance_rating'),
      ortam: avg('atmosphere_rating'),
    };
  })();

  // Öneri yüzdesi — 4 ve 5 yıldız = öneriyor
  const { oneriYuzdesi, oneriKisi } = (() => {
    if (reviewStats.length === 0) return { oneriYuzdesi: null, oneriKisi: null };
    const evet = reviewStats.filter((s) => s.rating >= 4).length;
    return {
      oneriYuzdesi: Math.round((evet / reviewStats.length) * 100),
      oneriKisi: evet,
    };
  })();

  // Anahtar kelimeler
  const anahrarKelimeler = kelimeCikar(detayliYorumlar);

  // Gallery photos from menu items
  const galleryPhotos: GaleriPhoto[] = (menuData?.items ?? [])
    .filter((i) => i.image_url)
    .slice(0, 4)
    .map((i) => ({ url: i.image_url!, name: i.name }));

  const popularItems: AcikMenuUrunKarti[] = (menuData?.items ?? [])
    .filter((i) => i.image_url && i.is_available)
    .slice(0, 4)
    .map(
      (i): AcikMenuUrunKarti => ({
        id: i.id,
        name: i.name,
        description: i.description,
        priceCents: i.price_cents,
        currency: i.currency,
        isAvailable: i.is_available,
        imageUrl: i.image_url,
        tags: i.tagList,
        allergens: i.allergens,
      }),
    );

  const menuItems = (menuData?.items ?? []).map((i) => ({
    id: i.id,
    name: i.name,
    price_cents: i.price_cents,
    is_available: i.is_available,
  }));

  const todayHours = business.hours?.find((h) => h.active) ?? null;
  const priceSymbol = priceLevelSymbol(business.priceLevel, business.medianPriceCents);
  const mapsHref =
    business.lat && business.lng
      ? `https://maps.google.com/?q=${business.lat},${business.lng}`
      : business.address
        ? `https://maps.google.com/?q=${encodeURIComponent(`${business.address} ${business.city ?? ''}`)}`
        : null;

  const siteUrl = appConfig.siteUrl().replace(/\/$/, '');
  const businessUrl = `${siteUrl}/isletme/${business.slug}`;

  const schema: Record<string, unknown> = {
    '@context': 'https://schema.org',
    '@type': 'Restaurant',
    '@id': businessUrl,
    name: business.name,
    url: businessUrl,
    description: business.description ?? undefined,
    image: business.coverUrl ?? business.logoUrl ?? undefined,
    servesCuisine: business.category ?? undefined,
    telephone: (business as any).phone ?? undefined,
    address: business.address
      ? {
          '@type': 'PostalAddress',
          streetAddress: business.address,
          addressLocality: (business as any).district ?? business.city ?? undefined,
          addressRegion: business.city ?? undefined,
          addressCountry: 'TR',
        }
      : undefined,
    menu: `${siteUrl}/m/${business.slug}`,
    aggregateRating:
      business.avgRating && business.reviewCount
        ? {
            '@type': 'AggregateRating',
            ratingValue: business.avgRating.toFixed(1),
            reviewCount: business.reviewCount,
            bestRating: '5',
            worstRating: '1',
          }
        : undefined,
  };
  Object.keys(schema).forEach((k) => schema[k] === undefined && delete schema[k]);

  const coverUrl = buildMenuImageUrl(business.coverUrl, { width: 1200, quality: 85 });

  return (
    <PublicShell>
      <main className="min-h-screen bg-bg pb-20">
        <script
          type="application/ld+json"
          dangerouslySetInnerHTML={{ __html: JSON.stringify(schema) }}
        />

        {/* ── Breadcrumb ─────────────────────────────────────────── */}
        <div className="mx-auto max-w-6xl px-4 pt-4 sm:px-6 lg:px-8">
          <nav className="flex items-center gap-1.5 text-sm text-muted" aria-label="Gezinme yolu">
            <Link href="/kesif" className="hover:text-primary transition-colors">Keşfet</Link>
            <Icon name="chevronRight" size={14} />
            {business.category && (
              <>
                <Link
                  href={`/kesif?category=${encodeURIComponent(business.category)}`}
                  className="hover:text-primary transition-colors"
                >
                  {business.category}
                </Link>
                <Icon name="chevronRight" size={14} />
              </>
            )}
            <span className="font-[800] text-textStrong truncate">{business.name}</span>
          </nav>
        </div>

        {/* ── Photo Gallery ──────────────────────────────────────── */}
        <div className="mx-auto mt-3 max-w-6xl px-4 sm:px-6 lg:px-8">
          {(() => {
            const allPhotos: GaleriPhoto[] = [
              ...(coverUrl ? [{ url: coverUrl, name: business.name }] : []),
              ...galleryPhotos,
            ];
            return (
              <div className="grid h-[340px] gap-2 overflow-hidden rounded-[24px] sm:h-[400px] lg:grid-cols-[1fr_340px]">
                {/* Ana cover */}
                <div className="relative overflow-hidden bg-cardAlt">
                  {coverUrl ? (
                    <FotoGalerisiTetik photos={allPhotos} index={0}>
                      <div className="relative h-full w-full" style={{ minHeight: 340 }}>
                        <Image
                          src={coverUrl}
                          alt={business.name}
                          fill
                          priority
                          sizes="(max-width: 1024px) 100vw, 820px"
                          className="object-cover transition-transform duration-300 group-hover:scale-[1.02]"
                        />
                      </div>
                    </FotoGalerisiTetik>
                  ) : (
                    <div
                      className="h-full w-full"
                      style={{ background: 'linear-gradient(135deg, #5c1515 0%, #7f1d1d 48%, #dc2626 100%)' }}
                    />
                  )}
                  {business.isOpenNow != null && (
                    <span
                      className={`pointer-events-none absolute left-4 top-4 inline-flex items-center gap-1.5 rounded-full px-3 py-1 text-xs font-[800] text-white ${business.isOpenNow ? 'bg-success' : 'bg-danger'}`}
                    >
                      <span className="h-1.5 w-1.5 rounded-full bg-white" />
                      {business.isOpenNow ? 'Açık' : 'Kapalı'}
                    </span>
                  )}
                </div>

                {/* 2×2 mini galeri */}
                {galleryPhotos.length >= 2 && (
                  <div className="relative hidden grid-cols-2 grid-rows-2 gap-2 lg:grid">
                    {galleryPhotos.slice(0, 4).map((photo, idx) => {
                      const photoUrl = buildMenuImageUrl(photo.url, { width: 340, quality: 78 }) ?? photo.url;
                      const allPhotosIdx = coverUrl ? idx + 1 : idx;
                      return (
                        <div
                          key={idx}
                          className="relative overflow-hidden bg-cardAlt"
                          style={{ borderRadius: idx === 1 ? '0 12px 0 0' : idx === 3 ? '0 0 12px 0' : undefined }}
                        >
                          <FotoGalerisiTetik photos={allPhotos} index={allPhotosIdx}>
                            <div className="relative h-full w-full" style={{ minHeight: 94 }}>
                              <Image
                                src={photoUrl}
                                alt={photo.name}
                                fill
                                sizes="170px"
                                className="object-cover transition-transform duration-300 group-hover:scale-[1.04]"
                              />
                            </div>
                          </FotoGalerisiTetik>
                        </div>
                      );
                    })}
                  </div>
                )}
              </div>
            );
          })()}
        </div>

        {/* ── Business header ────────────────────────────────────── */}
        <div className="mx-auto mt-6 max-w-6xl px-4 sm:px-6 lg:px-8">
          <div className="flex flex-col gap-4 rounded-[20px] border border-border bg-card p-5 shadow-yd1 sm:flex-row sm:items-start sm:justify-between">
            <div className="min-w-0 flex-1">
              <div className="mb-2 flex flex-wrap items-center gap-2">
                {business.isVerified && (
                  <span className="inline-flex items-center gap-1 rounded-full bg-primary/10 px-2.5 py-0.5 text-xs font-[800] text-primary">
                    <Icon name="check" size={12} /> Doğrulanmış
                  </span>
                )}
                {chainInfo && (
                  <span className="inline-flex items-center gap-1.5 rounded-full bg-amber-50 px-2.5 py-0.5 text-xs font-[800] text-amber-800 border border-amber-200/60">
                    <ZincirIkonu />
                    {chainInfo.chain_name}
                    {chainInfo.branch_count > 1 && (
                      <span className="font-[700] text-amber-600">· {chainInfo.branch_count} şube</span>
                    )}
                    {chainInfo.chain_is_verified && (
                      <Icon name="check" size={11} className="text-amber-600" />
                    )}
                  </span>
                )}
                {checkinCount > 0 && (
                  <span className="inline-flex items-center gap-1 rounded-full bg-orange-100 px-2.5 py-0.5 text-xs font-[800] text-orange-700">
                    🔥 {checkinCount} kişi şu an burada
                  </span>
                )}
              </div>
              <h1 className="text-2xl font-[900] leading-tight text-textStrong sm:text-3xl">
                {business.name}
              </h1>
              <p className="mt-1 text-sm text-muted">
                {[business.category, business.district, business.city].filter(Boolean).join(' · ')}
              </p>
              <div className="mt-3 flex flex-wrap items-center gap-3 text-sm">
                {business.avgRating != null && (
                  <span className="inline-flex items-center gap-1 font-[900] text-textStrong">
                    <Icon name="star" size={15} className="stroke-warning fill-warning" />
                    {business.avgRating.toFixed(1)}
                    {business.reviewCount != null && (
                      <span className="font-[700] text-muted">({business.reviewCount})</span>
                    )}
                  </span>
                )}
                {(business as any).distanceKm != null && (
                  <span className="font-[700] text-muted">{(business as any).distanceKm.toFixed(1)} km</span>
                )}
                {priceSymbol && <span className="font-[800] text-muted">{priceSymbol}</span>}
                {todayHours && (
                  <span className="font-[700] text-muted">
                    {todayHours.value !== 'Kapalı' ? `Açık · Kapanış ${todayHours.value.split('-')[1]?.trim() ?? ''}` : 'Bugün kapalı'}
                  </span>
                )}
              </div>
            </div>

            <div className="flex flex-wrap items-center gap-2 sm:flex-col sm:items-end lg:flex-row">
              <FavoriteButton businessId={business.id} label="Favorilere Ekle" />
              <ShareButton title={business.name} url={businessUrl} />
              {business.menuHref && (
                <Link
                  href={business.menuHref}
                  className="inline-flex min-h-[44px] items-center gap-2 rounded-[14px] px-5 text-sm font-[900] text-white shadow-[var(--yd-shadow-primary)] transition-all hover:-translate-y-px"
                  style={{ background: 'var(--yd-gradient-primary)' }}
                >
                  <Icon name="menu" size={16} className="stroke-white" />
                  Menü
                </Link>
              )}
            </div>
          </div>

          {/* ── Interactive tabs ──────────────────────────────────── */}
          <div className="mt-5">
            <IsletmeDetayTablari
              businessId={business.id}
              businessSlug={business.slug}
              businessName={business.name}
              businessIsVerified={business.isVerified ?? null}
              businessCategory={business.category ?? null}
              businessCity={business.city ?? null}
              businessDistrict={business.district ?? null}
              businessAddress={business.address ?? null}
              businessPhone={(business as any).phone ?? null}
              businessWebsite={(business as any).website ?? null}
              businessLat={(business as any).lat ?? null}
              businessLng={(business as any).lng ?? null}
              businessHours={business.hours ?? null}
              businessAvgRating={business.avgRating ?? null}
              businessReviewCount={business.reviewCount ?? null}
              businessIsOpenNow={business.isOpenNow ?? null}
              businessMenuHref={business.menuHref ?? null}
              businessDescription={business.description ?? null}
              businessLogoUrl={business.logoUrl ?? null}
              priceSymbol={priceSymbol}
              mapsHref={mapsHref}
              businessUrl={businessUrl}
              coverUrl={coverUrl}
              popularItems={popularItems}
              menuItems={menuItems}
              mealCards={mealCards.map((mc: MealCardPublicRow) => ({ key: mc.key, name: mc.name }))}
              galleryPhotos={galleryPhotos}
              yorumlar={detayliYorumlar}
              yorumlarToplam={reviewStats.length}
              yildizDagitimi={yildizDagitimi}
              altPuanOrt={altPuanOrt}
              oneriYuzdesi={oneriYuzdesi}
              oneriKisi={oneriKisi}
              anahrarKelimeler={anahrarKelimeler}
              similar={similar}
              checkinCount={checkinCount}
              todayHours={todayHours}
              medianPriceCents={business.medianPriceCents ?? null}
            />
          </div>
        </div>
      </main>
    </PublicShell>
  );
}

function ZincirIkonu() {
  return (
    <svg width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
      <polygon points="12 2 2 7 12 12 22 7 12 2" />
      <polyline points="2 17 12 22 22 17" />
      <polyline points="2 12 12 17 22 12" />
    </svg>
  );
}
