import type { Metadata } from 'next';
import { notFound } from 'next/navigation';
import { PublicShell } from '@/src/ui/acik/yerlesim';
import { Container } from '@/src/ui/acik/ortak';
import {
  IsletmeBasligi,
  IsletmeSaatleriBolumu,
  IsletmeBilgiPaneli,
  IsletmeKonumBolumu,
  SahiplenmeCagri,
  KalabalikGostergesi,
  YeniUrunlerBolumu,
  BolgeselFiyatEndeksi,
  FiyatGecmisiSparkline,
} from '@/src/ui/acik/isletme';
import { MenuCategoryBlock } from '@/src/ui/acik/acik-menu';
import { YorumlarBolumu } from '@/src/ui/acik/yorumlar';
import { getMarketplaceBusinessBySlug, getBusinessReviews } from '@/src/lib/veri/pazar-okuma';
import { getPublicMenuPageData } from '@/src/lib/acik-menu-sayfasi';
import { appConfig } from '@/src/lib/ayarlar';
import type { AcikMenuUrunKarti, AcikYorumKarti } from '@/src/ui/acik/tipler';
import { PaylasimDugmesi } from '@/src/ui/bilesenler/paylasim-dugmesi';
import { CheckinDugmesi, FiyatTakipDugmesi } from '@/src/ui/acik/eylem-istemcisi';
import { createSupabasePublicClient } from '@/src/lib/taban/acik';

export const revalidate = 300;

// Pre-render the 100 most recently created active business pages at build time.
export async function generateStaticParams(): Promise<Array<{ slug: string }>> {
  try {
    const { createSupabasePublicClient } = await import('@/src/lib/taban/acik');
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
  const description = business.description ?? `${business.name} menüsü, yorumları, adresi ve fiyat bilgileri.`;
  return {
    title,
    description,
    alternates: { canonical },
    openGraph: {
      title,
      description,
      url: canonical,
      images: [{ url: business.coverUrl || `${siteUrl}/sunucu/acik-grafik?title=${encodeURIComponent(business.name)}`, width: 1200, height: 630, alt: business.name }],
    },
  };
}

export default async function BusinessPage({ params }: Props) {
  const { slug } = await params;
  const business = await getMarketplaceBusinessBySlug(slug);
  if (!business) notFound();

  const [reviews, menuData, checkinCount, priceComparison, priceHistory] = await Promise.all([
    getBusinessReviews(business.id, 5),
    getPublicMenuPageData({ businessSlugOrId: business.slug }).catch(() => null),
    (createSupabasePublicClient() as any)
      .rpc('get_business_recent_checkins_v1', { p_business_id: business.id, p_hours: 2 })
      .then((r: any) => r?.data?.count ?? 0)
      .catch(() => 0),
    (createSupabasePublicClient() as any)
      .rpc('get_business_price_comparison_v1', { p_business_id: business.id, p_limit: 5 })
      .then((r: any) => (r?.data as any[]) ?? [])
      .catch(() => []),
    (createSupabasePublicClient() as any)
      .rpc('get_business_price_history_v1', { p_business_id: business.id, p_months: 6 })
      .then((r: any) => (r?.data as any[]) ?? [])
      .catch(() => []),
  ]);

  type MenuPreviewRow = { category: { id: string; [key: string]: unknown }; items: AcikMenuUrunKarti[] };
  const menuPreview: MenuPreviewRow[] = menuData
    ? menuData.categories.slice(0, 3).map((category) => ({
        category,
        items: menuData.items
          .filter((item) => item.category_id === category.id)
          .slice(0, 4)
          .map((item): AcikMenuUrunKarti => ({
            id: item.id,
            name: item.name,
            description: item.description,
            priceCents: item.price_cents,
            currency: item.currency,
            isAvailable: item.is_available,
            imageUrl: item.image_url,
            tags: item.tagList,
            allergens: item.allergens,
          })),
      }))
    : [];

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
    breadcrumb: (() => {
      const slugify = (t: string) => t.toLowerCase()
        .replace(/ğ/g,'g').replace(/ş/g,'s').replace(/ı/g,'i')
        .replace(/ç/g,'c').replace(/ö/g,'o').replace(/ü/g,'u')
        .replace(/\s+/g,'-').replace(/[^a-z0-9-]/g,'');
      const items: Array<Record<string, unknown>> = [
        { '@type': 'ListItem', position: 1, name: 'Yeedoy', item: siteUrl + '/' },
      ];
      if (business.city) {
        items.push({ '@type': 'ListItem', position: items.length + 1, name: business.city, item: `${siteUrl}/${slugify(business.city)}` });
      }
      if ((business as any).district) {
        items.push({ '@type': 'ListItem', position: items.length + 1, name: (business as any).district, item: `${siteUrl}/${slugify(business.city ?? '')}/${slugify((business as any).district)}` });
      }
      if (business.category) {
        items.push({ '@type': 'ListItem', position: items.length + 1, name: business.category, item: `${siteUrl}/${slugify(business.city ?? '')}/${slugify((business as any).district ?? '')}/${slugify(business.category)}` });
      }
      items.push({ '@type': 'ListItem', position: items.length + 1, name: business.name, item: businessUrl });
      return { '@type': 'BreadcrumbList', itemListElement: items };
    })(),
    aggregateRating: business.avgRating && business.reviewCount
      ? { '@type': 'AggregateRating', ratingValue: business.avgRating.toFixed(1), reviewCount: business.reviewCount, bestRating: '5', worstRating: '1' }
      : undefined,
    review: (reviews as AcikYorumKarti[]).slice(0, 3).map((r) => ({
      '@type': 'Review',
      reviewRating: { '@type': 'Rating', ratingValue: String(r.rating) },
      reviewBody: r.content?.slice(0, 300) ?? undefined,
      author: { '@type': 'Person', name: r.author ?? 'Yeedoy Kullanıcısı' },
      datePublished: r.createdAt,
    })),
  };
  // Boş alanları temizle
  Object.keys(schema).forEach((k) => schema[k] === undefined && delete schema[k]);

  return (
    <PublicShell>
      <main>
        <script type="application/ld+json" dangerouslySetInnerHTML={{ __html: JSON.stringify(schema) }} />
        {!business.isActive && (
          <div className="mx-auto max-w-5xl px-4 pt-4">
            <div className="flex items-start gap-3 rounded-2xl border border-danger/20 bg-danger/[0.06] px-4 py-3">
              <span className="mt-0.5 text-danger">⚠</span>
              <div>
                <p className="text-sm font-[800] text-danger">Bu işletme artık hizmet vermemektedir</p>
                <p className="mt-0.5 text-xs text-muted">Bilgiler arşiv amaçlı tutulmaktadır.</p>
              </div>
            </div>
          </div>
        )}
        <div className="flex items-start justify-between gap-3 px-4 pt-4 sm:px-6">
          <div />
          <PaylasimDugmesi
            url={businessUrl}
            title={`${business.name} | Yeedoy`}
            text={`${business.name}${business.city ? ` · ${business.city}` : ''} — menü ve yorumlar`}
            compact
          />
        </div>
        <IsletmeBasligi business={business} />
        <Container className="grid gap-6 py-6 lg:grid-cols-[1fr_320px]">
          <div className="grid gap-8">
            <IsletmeBilgiPaneli business={business} />
            <CheckinDugmesi businessId={business.id} />
            <KalabalikGostergesi count={checkinCount} />
            {business.description ? (
              <section className="rounded-[20px] border border-border bg-card p-5 shadow-yd1">
                <h2 className="text-xl font-[900] text-textStrong">İşletme hakkında</h2>
                <p className="mt-3 text-sm leading-7 text-muted">{business.description}</p>
              </section>
            ) : null}
            {/* Menü fotoğraf karuseli — Loop kaydırmalı görsel galeri */}
            {(() => {
              const photos = (menuData?.items ?? [])
                .filter((i) => i.image_url)
                .slice(0, 12);
              if (photos.length < 2) return null;
              return (
                <section>
                  <h2 className="mb-3 text-lg font-[900] text-textStrong">Menüden Kareler</h2>
                  <div className="flex gap-3 overflow-x-auto pb-1 [scrollbar-width:none] [-ms-overflow-style:none] [&::-webkit-scrollbar]:hidden">
                    {photos.map((item) => (
                      <div key={item.id} className="relative h-36 w-36 shrink-0 overflow-hidden rounded-2xl bg-cardAlt">
                        {/* eslint-disable-next-line @next/next/no-img-element */}
                        <img
                          src={item.image_url!}
                          alt={item.name}
                          className="h-full w-full object-cover"
                          loading="lazy"
                        />
                        <div className="absolute inset-x-0 bottom-0 bg-gradient-to-t from-black/60 to-transparent p-2">
                          <p className="truncate text-[10px] font-[700] text-white">{item.name}</p>
                        </div>
                      </div>
                    ))}
                  </div>
                </section>
              );
            })()}
            <YeniUrunlerBolumu newItems={menuData?.items?.slice(0, 4)} />
            {menuPreview.length > 0 ? (
              <section className="grid gap-6">
                {menuPreview.map(({ category, items }) => (
                  <MenuCategoryBlock key={category.id} title={`Menüden: ${category.id.slice(0, 8)}`} items={items} />
                ))}
              </section>
            ) : null}
            <YorumlarBolumu reviews={reviews} businessSlug={business.slug} />
          </div>
          <aside className="grid content-start gap-4">
            <IsletmeKonumBolumu business={business} />
            <IsletmeSaatleriBolumu hours={business.hours} />
            <BolgeselFiyatEndeksi comparison={priceComparison} />
            <FiyatGecmisiSparkline history={priceHistory} shareUrl={businessUrl} />
            <FiyatTakipDugmesi businessId={business.id} />
            <SahiplenmeCagri businessSlug={business.slug} />
          </aside>
        </Container>
      </main>
    </PublicShell>
  );
}


