'use client';

import { useEffect, useState } from 'react';
import Image from 'next/image';
import Link from 'next/link';
import {
  Flame, Hamburger, UtensilsCrossed, Cookie, HandPlatter, CupSoda, Cake,
  Droplet, Pizza, Sandwich, Drumstick, Fish, Salad, Wheat, Soup,
  Beef, Utensils,
  type LucideIcon,
} from 'lucide-react';
import { buildMenuImageUrl } from '@/src/lib/medya-adresi';
import { bulVarsayilanYemekGorseli, type StockDishImage } from '@/src/lib/menu/varsayilan-yemek-gorseli';
import { getStokYemekKutuphanesi } from '@/src/lib/menu/stok-yemek-kutuphanesi';
import { getTranslationValue } from '@/src/lib/acik-menu-sayfasi';
import type { PublicMenuPageData } from '@/src/lib/acik-menu-sayfasi';
import type { MenuItemRecord } from '@/src/lib/veri/menu-okuma';
import { allergenLabels, type AppLang, type MenuCopy } from '@/src/lib/ceviri';

// ── Sabitler ─────────────────────────────────────────────────────────────────

const FEATURED_ID = '__featured__';
const INITIAL_SHOW = 5;

const ALLERGEN_EMOJI: Record<string, string> = {
  gluten: '🌾',
  milk: '🥛',
  eggs: '🥚',
  fish: '🐟',
  shellfish: '🦐',
  peanuts: '🥜',
  treenuts: '🌰',
  soy: '🫘',
  celery: '🌿',
  mustard: '🌼',
  sesame: '🫚',
  sulphites: '🍷',
  lupin: '🌸',
  molluscs: '🐚',
};

function kategoriIkonu(name: string): LucideIcon {
  const n = name.toLowerCase();
  if (n.includes('öne') || n.includes('popüler') || n.includes('özel')) return Flame;
  if (n.includes('burger')) return Hamburger;
  if (n.includes('menü') || n.includes('kombo')) return UtensilsCrossed;
  if (n.includes('aperatif') || n.includes('atıştır')) return Cookie;
  if (n.includes('yan') || n.includes('garnitür')) return HandPlatter;
  if (n.includes('içecek') || n.includes('drink') || n.includes('su')) return CupSoda;
  if (n.includes('tatlı') || n.includes('dessert')) return Cake;
  if (n.includes('sos') || n.includes('sauce')) return Droplet;
  if (n.includes('pizza')) return Pizza;
  if (n.includes('kebap') || n.includes('döner')) return Sandwich;
  if (n.includes('tavuk') || n.includes('chicken')) return Drumstick;
  if (n.includes('balık') || n.includes('fish')) return Fish;
  if (n.includes('salata')) return Salad;
  if (n.includes('makarna') || n.includes('pasta')) return Wheat;
  if (n.includes('çorba')) return Soup;
  if (n.includes('pide') || n.includes('lahmacun')) return UtensilsCrossed;
  if (n.includes('izgara') || n.includes('et') || n.includes('pirzola')) return Beef;
  return Utensils;
}

function fiyat(cents: number | null, priceOnRequest: string): string {
  if (cents == null) return priceOnRequest;
  return `₺${(cents / 100).toFixed(0)}`;
}

function kalori(item: MenuItemRecord): string | null {
  const min = item.calories_min;
  const max = item.calories_max;
  if (min == null && max == null) return null;
  if (min != null && max != null && min !== max) return `~${Math.round((min + max) / 2)} kcal`;
  return `~${min ?? max} kcal`;
}

// ── Tip ──────────────────────────────────────────────────────────────────────

export type MenuDuzenProps = {
  data: PublicMenuPageData;
  isOpenNow: boolean | null;
  todayHours: string | null;
  businessName: string;
  lang: AppLang;
  labels: MenuCopy;
  langSwitchHrefTr: string;
  langSwitchHrefEn: string;
};

// ── Ana bileşen ───────────────────────────────────────────────────────────────

export function MenuDuzen({
  data, isOpenNow, todayHours, businessName, lang, labels, langSwitchHrefTr, langSwitchHrefEn,
}: MenuDuzenProps) {
  const { business, categories, items, media } = data;

  const [activeCatId, setActiveCatId] = useState<string>(FEATURED_ID);
  const [query, setQuery] = useState('');
  const [showMoreMap, setShowMoreMap] = useState<Record<string, boolean>>({});
  const [collapsedMap, setCollapsedMap] = useState<Record<string, boolean>>({});
  const [stokKutuphanesi, setStokKutuphanesi] = useState<StockDishImage[]>([]);

  useEffect(() => {
    getStokYemekKutuphanesi().then(setStokKutuphanesi);
  }, []);

  const catNameMap = new Map<string, string>(
    categories.map((cat, index) => [
      cat.id,
      getTranslationValue({
        translations: data.translations,
        entityType: 'category',
        entityId: cat.id,
        locale: lang,
        field: 'name',
        fallback: `Kategori ${index + 1}`,
      }) ?? `Kategori ${index + 1}`,
    ]),
  );

  const featuredItems = items.filter((i) => i.image_url && i.is_available !== false).slice(0, 8);

  const itemsByCat = new Map<string, MenuItemRecord[]>();
  for (const item of items) {
    if (!item.category_id) continue;
    const list = itemsByCat.get(item.category_id) ?? [];
    list.push(item);
    itemsByCat.set(item.category_id, list);
  }

  function matches(item: MenuItemRecord): boolean {
    if (!query.trim()) return true;
    const q = query.toLowerCase();
    return (
      item.name.toLowerCase().includes(q) ||
      (item.description ?? '').toLowerCase().includes(q)
    );
  }

  function scrollToSection(catId: string) {
    setActiveCatId(catId);
    const el = document.getElementById(`mcat-${catId}`);
    if (el) el.scrollIntoView({ behavior: 'smooth', block: 'start' });
  }

  const biz = business as Record<string, unknown>;
  const orderLinks: Array<{ label: string; url: string; emoji: string }> = [
    biz.order_yemeksepeti_url ? { label: 'Yemeksepeti', url: biz.order_yemeksepeti_url as string, emoji: '🛵' } : null,
    biz.order_trendyolgo_url ? { label: 'Trendyol Go', url: biz.order_trendyolgo_url as string, emoji: '🛵' } : null,
    biz.order_getir_url ? { label: 'Getir', url: biz.order_getir_url as string, emoji: '🛵' } : null,
  ].filter((x): x is { label: string; url: string; emoji: string } => x !== null);

  const sidebarCats = [
    { id: FEATURED_ID, name: labels.featuredCategoryLabel, icon: Flame },
    ...categories.map((c) => {
      const name = catNameMap.get(c.id) ?? 'Kategori';
      return { id: c.id, name, icon: kategoriIkonu(name) };
    }),
  ];

  const logoUrl = buildMenuImageUrl(media.logoUrl ?? null, { width: 320, quality: 90 });
  const coverUrl = buildMenuImageUrl(media.coverUrl ?? null, { width: 320, quality: 90 });
  const thumbUrl = logoUrl ?? coverUrl;

  return (
    <div>
      {/* ── İşletme başlığı ───────────────────────────────────────────────── */}
      <div className="border-b border-border bg-card">
        <div className="mx-auto max-w-7xl px-4 py-5 sm:px-6">

          {/* Breadcrumb */}
          <nav className="mb-4 flex items-center gap-1 text-xs font-bold text-muted" aria-label="Breadcrumb">
            <Link href="/" className="hover:text-primary transition-colors">{labels.breadcrumbDiscover}</Link>
            <ChevronRight />
            <Link href="/kesif" className="hover:text-primary transition-colors">{labels.breadcrumbRestaurants}</Link>
            <ChevronRight />
            <Link href={`/isletme/${business.public_slug ?? business.slug ?? business.id}`} className="hover:text-primary transition-colors">
              {businessName}
            </Link>
            <ChevronRight />
            <span className="text-textStrong" aria-current="page">{labels.breadcrumbMenu}</span>
          </nav>

          {/* İşletme kartı */}
          <div className="flex flex-wrap items-start gap-5">
            {/* Kapak görseli */}
            <div className="relative h-36 w-36 shrink-0 overflow-hidden rounded-2xl border border-border bg-surface shadow-yd1 sm:h-40 sm:w-40">
              {thumbUrl ? (
                <Image
                  src={thumbUrl}
                  alt={businessName}
                  fill
                  sizes="(max-width:640px) 144px, 160px"
                  className="object-cover"
                  priority
                />
              ) : (
                <div className="flex h-full w-full items-center justify-center text-4xl" aria-hidden="true">🍽️</div>
              )}
            </div>

            {/* Bilgi */}
            <div className="flex-1 min-w-0">
              <div className="flex flex-wrap items-center gap-2">
                <h1 className="text-xl font-black leading-tight text-textStrong sm:text-2xl">{businessName}</h1>
                {business.is_verified && (
                  <span
                    className="inline-flex h-6 w-6 items-center justify-center rounded-full bg-primary text-white"
                    title={labels.verifiedBusinessLabel}
                    aria-label={labels.verifiedBusinessLabel}
                  >
                    <svg width="12" height="12" viewBox="0 0 12 12" fill="none" aria-hidden="true">
                      <path d="M2 6l2.5 2.5L10 3.5" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round" />
                    </svg>
                  </span>
                )}
                <div className="flex items-center gap-1 text-xs font-black">
                  <a
                    href={langSwitchHrefTr}
                    className={lang === 'tr' ? 'text-primary underline' : 'text-muted hover:text-primary'}
                  >
                    TR
                  </a>
                  <span className="text-muted" aria-hidden="true">|</span>
                  <a
                    href={langSwitchHrefEn}
                    className={lang === 'en' ? 'text-primary underline' : 'text-muted hover:text-primary'}
                  >
                    EN
                  </a>
                </div>
              </div>

              {/* Kategori ve konum etiketleri */}
              <div className="mt-1.5 flex flex-wrap items-center gap-1.5 text-sm font-bold text-muted">
                {business.category && <span>{business.category}</span>}
                {business.neighborhood && (
                  <>
                    <span aria-hidden="true">•</span>
                    <span>{business.neighborhood}</span>
                  </>
                )}
                {business.district && (
                  <>
                    <span aria-hidden="true">•</span>
                    <span>{business.district}</span>
                  </>
                )}
              </div>

              {/* Açık/Kapalı + saat */}
              <div className="mt-2.5 flex flex-wrap items-center gap-3 text-sm font-bold">
                {isOpenNow !== null && (
                  <span
                    className={`inline-flex items-center gap-1 rounded-full px-2.5 py-1 text-xs font-black ${
                      isOpenNow
                        ? 'bg-success/10 text-success'
                        : 'bg-danger/10 text-danger'
                    }`}
                  >
                    <span className="text-[8px]" aria-hidden="true">●</span>
                    {isOpenNow ? 'Açık' : 'Kapalı'}
                  </span>
                )}
                {todayHours && (
                  <span className="text-xs text-muted">
                    <span aria-hidden="true">🕐 </span>{todayHours}
                  </span>
                )}
                {business.phone && (
                  <a
                    href={`tel:${business.phone}`}
                    className="text-xs text-muted hover:text-primary transition-colors"
                  >
                    <span aria-hidden="true">📞 </span>{business.phone}
                  </a>
                )}
              </div>

              {/* Aksiyon butonları */}
              <div className="mt-3 flex flex-wrap items-center gap-2">
                <button
                  type="button"
                  className="inline-flex min-h-9 items-center gap-1.5 rounded-full border border-border bg-card px-4 text-xs font-black text-textStrong hover:border-danger hover:text-danger transition-colors"
                  aria-label={labels.favoriteButtonAria}
                >
                  <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" aria-hidden="true">
                    <path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z" />
                  </svg>
                  {labels.favoriteButton}
                </button>

                <button
                  type="button"
                  className="inline-flex min-h-9 items-center gap-1.5 rounded-full border border-border bg-card px-4 text-xs font-black text-textStrong hover:border-primary hover:text-primary transition-colors"
                  onClick={() => { if (navigator.share) navigator.share({ title: businessName, url: window.location.href }); }}
                  aria-label={labels.shareButtonAria}
                >
                  <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" aria-hidden="true">
                    <circle cx="18" cy="5" r="3" /><circle cx="6" cy="12" r="3" /><circle cx="18" cy="19" r="3" />
                    <line x1="8.59" y1="13.51" x2="15.42" y2="17.49" /><line x1="15.41" y1="6.51" x2="8.59" y2="10.49" />
                  </svg>
                  {labels.shareButton}
                </button>

                {business.reservation_url && (
                  <Link
                    href={business.reservation_url}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="inline-flex min-h-9 items-center gap-1.5 rounded-2xl bg-primary px-4 text-xs font-black text-white hover:bg-primary/90 transition-colors"
                  >
                    🪑 {labels.reserveTableButton}
                  </Link>
                )}

                {orderLinks.map((link) => (
                  <Link
                    key={link.label}
                    href={link.url}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="inline-flex min-h-9 items-center gap-1.5 rounded-2xl border border-border bg-card px-4 text-xs font-black text-textStrong hover:border-primary hover:text-primary transition-colors"
                  >
                    {link.emoji} {link.label}
                  </Link>
                ))}
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* ── 2-sütun layout ──────────────────────────────────────────────────── */}
      <div className="mx-auto flex max-w-7xl items-start gap-5 px-4 py-5 sm:px-6">

        {/* ── Sol kenar çubuğu ── */}
        <aside className="hidden lg:block w-52 shrink-0 sticky top-20 self-start">
          <div className="overflow-hidden rounded-2xl border border-border bg-card py-3">
            <p className="px-4 pb-2 pt-1 text-[11px] font-black uppercase tracking-widest text-muted">
              {labels.menuCategoriesTitle}
            </p>

            {sidebarCats.map((cat) => {
              const isActive = activeCatId === cat.id;
              return (
                <button
                  key={cat.id}
                  type="button"
                  onClick={() => scrollToSection(cat.id)}
                  className={`flex w-full items-center gap-2.5 border-l-[3px] px-4 py-2.5 text-left text-sm font-extrabold transition-colors ${
                    isActive
                      ? 'border-primary bg-primary/5 text-primary'
                      : 'border-transparent text-textStrong hover:bg-surface hover:text-primary'
                  }`}
                >
                  <cat.icon className="h-4 w-4 shrink-0" aria-hidden="true" />
                  <span className="truncate">{cat.name}</span>
                </button>
              );
            })}

            <div className="mx-3 mt-4 rounded-2xl bg-primary/5 p-3">
              <p className="text-xs font-black text-primary">{labels.promoBannerTitle} 🎉</p>
              <p className="mt-0.5 text-[11px] font-bold text-muted">{labels.promoBannerBody}</p>
            </div>
          </div>
        </aside>

        {/* ── Menü içeriği ── */}
        <div className="flex-1 min-w-0 space-y-8">

          {/* Arama */}
          <div className="relative">
            <span className="pointer-events-none absolute inset-y-0 left-3.5 flex items-center text-muted" aria-hidden="true">
              <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round">
                <circle cx="11" cy="11" r="8" /><path d="m21 21-4.35-4.35" />
              </svg>
            </span>
            <input
              type="search"
              placeholder={labels.searchPlaceholder}
              value={query}
              onChange={(e) => setQuery(e.target.value)}
              className="h-11 w-full rounded-2xl border border-border bg-card pl-11 pr-4 text-sm font-bold text-textStrong placeholder:text-muted focus:border-primary focus:outline-hidden transition-colors"
            />
          </div>

          {/* ── Öne çıkanlar (grid) ── */}
          {featuredItems.filter(matches).length > 0 && (
            <section id={`mcat-${FEATURED_ID}`}>
              <div className="mb-4 flex items-baseline justify-between">
                <div>
                  <h2 className="text-lg font-black text-textStrong">
                    <span aria-hidden="true">🔥 </span>{labels.featuredItems}
                  </h2>
                  <p className="mt-0.5 text-xs font-bold text-muted">{labels.featuredItemsSubtitle}</p>
                </div>
              </div>
              <div className="grid grid-cols-2 gap-3 sm:grid-cols-4">
                {featuredItems.filter(matches).map((item) => (
                  <UrunKarti key={item.id} item={item} translations={data.translations} lang={lang} labels={labels} />
                ))}
              </div>
            </section>
          )}

          {/* ── Kategori bölümleri (liste) ── */}
          {categories.map((cat) => {
            const catItems = (itemsByCat.get(cat.id) ?? []).filter(matches);
            if (catItems.length === 0) return null;

            const catName = catNameMap.get(cat.id) ?? 'Kategori';
            const CategoryIcon = kategoriIkonu(catName);
            const isCollapsed = collapsedMap[cat.id] ?? false;
            const showMore = showMoreMap[cat.id] ?? false;
            const visibleItems = showMore ? catItems : catItems.slice(0, INITIAL_SHOW);

            return (
              <section key={cat.id} id={`mcat-${cat.id}`}>
                <button
                  type="button"
                  onClick={() => setCollapsedMap((p) => ({ ...p, [cat.id]: !p[cat.id] }))}
                  className="mb-3 flex w-full items-center gap-2 text-left"
                  aria-expanded={!isCollapsed}
                >
                  <CategoryIcon aria-hidden="true" className="h-5 w-5 shrink-0 text-primary" />
                  <h2 className="flex-1 text-lg font-black text-textStrong">{catName}</h2>
                  <svg
                    width="16" height="16" viewBox="0 0 24 24" fill="none"
                    stroke="currentColor" strokeWidth="2.5" strokeLinecap="round"
                    className={`shrink-0 text-muted transition-transform ${isCollapsed ? '' : 'rotate-180'}`}
                    aria-hidden="true"
                  >
                    <path d="m18 15-6-6-6 6" />
                  </svg>
                </button>

                {!isCollapsed && (
                  <>
                    <div className="divide-y divide-border overflow-hidden rounded-2xl border border-border bg-card">
                      {visibleItems.map((item) => (
                        <UrunSatiri
                          key={item.id}
                          item={item}
                          stokKutuphanesi={stokKutuphanesi}
                          translations={data.translations}
                          lang={lang}
                          labels={labels}
                        />
                      ))}
                    </div>

                    {!showMore && catItems.length > INITIAL_SHOW && (
                      <button
                        type="button"
                        onClick={() => setShowMoreMap((p) => ({ ...p, [cat.id]: true }))}
                        className="mt-3 flex w-full items-center justify-center gap-1.5 rounded-2xl border border-border bg-card py-2.5 text-sm font-black text-textStrong hover:bg-surface transition-colors"
                      >
                        {labels.showMoreButton}
                        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" aria-hidden="true">
                          <path d="m6 9 6 6 6-6" />
                        </svg>
                      </button>
                    )}
                  </>
                )}
              </section>
            );
          })}

          {/* Arama sonucu yok */}
          {query.trim() &&
            featuredItems.filter(matches).length === 0 &&
            categories.every((c) => (itemsByCat.get(c.id) ?? []).filter(matches).length === 0) && (
              <div className="rounded-2xl border border-border bg-card px-6 py-12 text-center">
                <p className="text-3xl" aria-hidden="true">🔍</p>
                <p className="mt-3 text-sm font-black text-textStrong">
                  {labels.noSearchResultsPrefix} &ldquo;{query}&rdquo; {labels.noSearchResultsSuffix}
                </p>
                <p className="mt-1 text-xs font-bold text-muted">{labels.noSearchResultsHint}</p>
              </div>
            )}
        </div>
      </div>
    </div>
  );
}

// ── Ürün kartı (grid — görselli) ─────────────────────────────────────────────

function UrunKarti({
  item, translations, lang, labels,
}: {
  item: MenuItemRecord;
  translations: PublicMenuPageData['translations'];
  lang: AppLang;
  labels: MenuCopy;
}) {
  const imgUrl = buildMenuImageUrl(item.image_url ?? null, { width: 300, quality: 80 });
  const isAvailable = item.is_available !== false;
  const kcal = kalori(item);
  const name = getTranslationValue({
    translations, entityType: 'item', entityId: item.id, locale: lang, field: 'name', fallback: item.name,
  }) ?? item.name;
  const description = getTranslationValue({
    translations, entityType: 'item', entityId: item.id, locale: lang, field: 'description', fallback: item.description,
  }) ?? item.description;

  return (
    <div
      className={`group flex flex-col overflow-hidden rounded-2xl border border-border bg-card transition-shadow hover:shadow-ydMd ${
        !isAvailable ? 'opacity-60' : ''
      }`}
    >
      {/* Görsel */}
      <div className="relative aspect-square w-full overflow-hidden">
        {imgUrl ? (
          <Image
            src={imgUrl}
            alt={name}
            fill
            sizes="(max-width:640px) 50vw, 25vw"
            className="object-cover transition-transform duration-300 group-hover:scale-105"
          />
        ) : (
          <div className="flex h-full w-full items-center justify-center bg-surface text-3xl" aria-hidden="true">
            🍽️
          </div>
        )}
        {!isAvailable && (
          <div className="absolute inset-0 flex items-center justify-center bg-card/60">
            <span className="rounded-xl bg-card px-2 py-1 text-[11px] font-black text-muted">{labels.soldOut}</span>
          </div>
        )}
      </div>

      {/* Bilgi */}
      <div className="flex flex-1 flex-col p-3">
        <p className="text-sm font-black text-textStrong line-clamp-1">{name}</p>
        {description && (
          <p className="mt-0.5 text-[11px] font-bold text-muted line-clamp-2">{description}</p>
        )}

        {/* Kalori etiketi */}
        {kcal && (
          <p className="mt-1 text-[10px] font-bold text-muted">{kcal}</p>
        )}

        <div className="mt-auto pt-2">
          {isAvailable ? (
            <span className="text-sm font-black text-textStrong">{fiyat(item.price_cents, labels.priceOnRequest)}</span>
          ) : (
            <span className="text-xs font-extrabold text-muted">—</span>
          )}
        </div>
      </div>
    </div>
  );
}

// ── Ürün satırı (yatay liste) ────────────────────────────────────────────────

function UrunSatiri({
  item, stokKutuphanesi, translations, lang, labels,
}: {
  item: MenuItemRecord;
  stokKutuphanesi: StockDishImage[];
  translations: PublicMenuPageData['translations'];
  lang: AppLang;
  labels: MenuCopy;
}) {
  const varsayilanUrl = item.image_url ? null : bulVarsayilanYemekGorseli(item.name, stokKutuphanesi);
  const imgUrl = buildMenuImageUrl(item.image_url ?? varsayilanUrl, { width: 200, quality: 80 });
  const isAvailable = item.is_available !== false;
  const kcal = kalori(item);
  const allergens = item.allergens ?? [];
  const allergenLabelsForLang = allergenLabels[lang];
  const name = getTranslationValue({
    translations, entityType: 'item', entityId: item.id, locale: lang, field: 'name', fallback: item.name,
  }) ?? item.name;
  const description = getTranslationValue({
    translations, entityType: 'item', entityId: item.id, locale: lang, field: 'description', fallback: item.description,
  }) ?? item.description;

  return (
    <div className={`flex items-start gap-3 p-4 ${!isAvailable ? 'opacity-60' : ''}`}>
      {/* Görsel */}
      {imgUrl ? (
        <div className="relative h-20 w-20 shrink-0 overflow-hidden rounded-xl">
          <Image src={imgUrl} alt={name} fill sizes="80px" className="object-cover" />
        </div>
      ) : (
        <div className="flex h-20 w-20 shrink-0 items-center justify-center rounded-xl bg-surface text-2xl" aria-hidden="true">
          🍽️
        </div>
      )}

      {/* Metin */}
      <div className="flex flex-1 min-w-0 flex-col gap-0.5">
        <p className="text-sm font-black text-textStrong line-clamp-1">{name}</p>
        {description && (
          <p className="text-xs font-bold text-muted line-clamp-2">{description}</p>
        )}

        {/* Kalori + etiketler */}
        <div className="mt-1 flex flex-wrap items-center gap-1">
          {kcal && (
            <span className="rounded-full bg-surface px-2 py-0.5 text-[10px] font-extrabold text-muted">
              🔥 {kcal}
            </span>
          )}
          {item.tagList?.slice(0, 2).map((tag) => (
            <span key={tag} className="rounded-full bg-surface px-2 py-0.5 text-[10px] font-extrabold text-muted capitalize">
              {tag}
            </span>
          ))}
        </div>

        {/* Alerjenler */}
        {allergens.length > 0 && (
          <div className="mt-1 flex flex-wrap items-center gap-1">
            {allergens.map((a) => (
              <span
                key={a}
                className="inline-flex items-center gap-0.5 rounded-full bg-amber-50 px-1.5 py-0.5 text-[10px] font-extrabold text-amber-700 ring-1 ring-amber-200"
                title={`${labels.allergenPrefix}: ${allergenLabelsForLang[a as keyof typeof allergenLabelsForLang] ?? a}`}
              >
                <span aria-hidden="true">{ALLERGEN_EMOJI[a] ?? '⚠️'}</span>
                {allergenLabelsForLang[a as keyof typeof allergenLabelsForLang] ?? a}
              </span>
            ))}
          </div>
        )}
      </div>

      {/* Sağ: fiyat */}
      <div className="ml-2 shrink-0 text-right">
        {isAvailable ? (
          <span className="text-sm font-black text-textStrong">{fiyat(item.price_cents, labels.priceOnRequest)}</span>
        ) : (
          <span className="rounded-xl border border-border px-2 py-1 text-[11px] font-extrabold text-muted">
            {labels.soldOut}
          </span>
        )}
      </div>
    </div>
  );
}

// ── Yardımcı ikon ────────────────────────────────────────────────────────────

function ChevronRight() {
  return (
    <svg width="10" height="10" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" aria-hidden="true" className="text-muted">
      <path d="m9 18 6-6-6-6" />
    </svg>
  );
}
