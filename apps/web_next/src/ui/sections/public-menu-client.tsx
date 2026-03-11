/* eslint-disable @next/next/no-img-element */
'use client';

import dynamic from 'next/dynamic';
import type { MouseEvent, ReactNode } from 'react';
import { startTransition, useDeferredValue, useEffect, useRef, useState } from 'react';
import { usePathname, useRouter } from 'next/navigation';
import type { BrandTheme, BrandThemeDefinition } from '@/src/lib/brand-theme';
import { formatBusinessLocation, formatCurrency, formatDateLabel } from '@/src/lib/format';
import type { AppLang, MenuCopy } from '@/src/lib/i18n';
import { PUBLIC_QR_LEGAL_LINKS } from '@/src/lib/legal-links';
import { buildBusinessMenuHref, buildQrHref } from '@/src/lib/menu-links';
import { getTranslationValue } from '@/src/lib/menu-text';
import { appendMediaVersion } from '@/src/lib/media-url';
import { getPresentationViewModel } from '@/src/lib/presentation-view';
import type { PublicMenuPageData } from '@/src/lib/public-menu-page';

const ItemDetailSheet = dynamic(
  () => import('@/src/ui/sections/menu-item-detail-sheet').then((module) => module.MenuItemDetailSheet),
  { ssr: false },
);

type Props = {
  lang: AppLang;
  labels: MenuCopy;
  brandTheme: BrandTheme;
  themeDefinition: BrandThemeDefinition;
  themeOptions: Array<{
    id: BrandTheme;
    label: string;
  }>;
  blurDataUrl: string;
  data: PublicMenuPageData;
  isPreview: boolean;
  selectedCategoryId?: string | null;
};

type TrackPayload = {
  eventName: 'page_view' | 'category_view' | 'item_view' | 'item_click';
  businessId: string;
  menuId: string;
  meta?: Record<string, unknown>;
};

export function PublicMenuClient({
  lang,
  labels,
  brandTheme,
  themeDefinition,
  themeOptions,
  blurDataUrl,
  data,
  isPreview,
  selectedCategoryId,
}: Props) {
  const router = useRouter();
  const pathname = usePathname();
  const resultsRef = useRef<HTMLElement | null>(null);
  const brand = themeDefinition;
  const presentationView = getPresentationViewModel(data.presentation, brandTheme, themeDefinition);
  const [query, setQuery] = useState('');
  const [activeCategoryId, setActiveCategoryId] = useState(selectedCategoryId ?? 'all');
  const deferredQuery = useDeferredValue(query);
  const selectedItem = data.selectedItem;
  const businessPath = data.business;
  const businessLocation = formatBusinessLocation(data.business);
  const mediaVersion = data.presentation.updatedAt;
  const heroImageUrl = appendMediaVersion(
    data.presentation.backgroundUrl || data.media.coverUrl,
    mediaVersion,
  );
  const brandLogoUrl = appendMediaVersion(data.media.logoUrl, mediaVersion);
  const businessName =
    getTranslationValue({
      translations: data.translations,
      entityType: 'business',
      entityId: data.business.id,
      locale: lang,
      field: 'name',
      fallback: data.business.name,
    }) ?? data.business.name;
  const categoriesWithLabels = data.categories.map((category) => ({
    id: category.id,
    label:
      getTranslationValue({
        translations: data.translations,
        entityType: 'category',
        entityId: category.id,
        locale: lang,
        field: 'name',
        fallback: `${labels.category} ${category.sort_order + 1}`,
      }) ?? `${labels.category} ${category.sort_order + 1}`,
  }));

  useEffect(() => {
    setActiveCategoryId(selectedCategoryId ?? 'all');
  }, [selectedCategoryId]);

  useEffect(() => {
    if (isPreview) return;
    void trackEvent({
      eventName: 'page_view',
      businessId: data.business.id,
      menuId: data.menu.id,
      meta: {
        path: pathname,
        lang,
        theme: brandTheme,
      },
    });
  }, [brandTheme, data.business.id, data.menu.id, isPreview, lang, pathname]);

  useEffect(() => {
    if (isPreview) return;
    if (!selectedCategoryId) return;
    void trackEvent({
      eventName: 'category_view',
      businessId: data.business.id,
      menuId: data.menu.id,
      meta: {
        category_id: selectedCategoryId,
        theme: brandTheme,
      },
    });
  }, [brandTheme, data.business.id, data.menu.id, isPreview, selectedCategoryId]);

  useEffect(() => {
    if (isPreview) return;
    if (!selectedItem) return;
    void trackEvent({
      eventName: 'item_view',
      businessId: data.business.id,
      menuId: data.menu.id,
      meta: {
        item_id: selectedItem.id,
        theme: brandTheme,
      },
    });
  }, [brandTheme, data.business.id, data.menu.id, isPreview, selectedItem]);

  const filteredItems = data.items.filter((item) => {
    if (activeCategoryId !== 'all' && item.category_id !== activeCategoryId) return false;
    if (!deferredQuery.trim()) return true;

    const translatedName =
      getTranslationValue({
        translations: data.translations,
        entityType: 'item',
        entityId: item.id,
        locale: lang,
        field: 'name',
        fallback: item.name,
      }) ?? item.name;
    const translatedDescription =
      getTranslationValue({
        translations: data.translations,
        entityType: 'item',
        entityId: item.id,
        locale: lang,
        field: 'description',
        fallback: item.description,
      }) ?? item.description;

    const haystack = [translatedName, translatedDescription, item.tagList.join(' ')]
      .filter(Boolean)
      .join(' ')
      .toLowerCase();

    return haystack.includes(deferredQuery.trim().toLowerCase());
  });

  const featuredItems = data.items.filter((item) =>
    item.tagList.some((entry) => {
      const lowered = entry.toLowerCase();
      return (
        lowered.includes('popular') ||
        lowered.includes('featured') ||
        lowered.includes('one') ||
        lowered.includes('chef')
      );
    }),
  );

  const tags = Array.from(
    new Set(
      filteredItems
        .flatMap((item) => item.tagList)
        .map((entry) => entry.trim())
        .filter(Boolean),
    ),
  ).slice(0, 10);
  const activeCategoryLabel =
    activeCategoryId === 'all'
      ? labels.allCategories
      : categoriesWithLabels.find((category) => category.id === activeCategoryId)?.label ?? labels.allCategories;

  function handleCategorySelect(categoryId: string, target?: HTMLButtonElement | null) {
    setActiveCategoryId(categoryId);
    const href = buildBusinessMenuHref({
      business: businessPath,
      categoryId: categoryId === 'all' ? null : categoryId,
      lang,
      theme: brandTheme,
      preview: isPreview,
    });
    target?.scrollIntoView({
      behavior: 'smooth',
      inline: 'center',
      block: 'nearest',
    });
    resultsRef.current?.scrollIntoView({
      behavior: 'smooth',
      block: 'start',
    });
    startTransition(() => {
      router.push(href);
    });
  }

  function handleThemeSelect(nextTheme: BrandTheme) {
    const params = new URLSearchParams();
    params.set('lang', lang);
    params.set('theme', nextTheme);
    if (isPreview) params.set('preview', '1');
    startTransition(() => {
      router.push(`${pathname}?${params.toString()}`);
    });
  }

  return (
    <div
      className={`space-y-6 rounded-[36px] p-3 pb-10 sm:p-4 ${presentationView.fontScaleClassName}`}
      style={presentationView.pageStyle}
    >
      <section className="overflow-hidden rounded-[32px] border border-border bg-card shadow-yd2">
        <div className="relative min-h-[340px] overflow-hidden p-6 text-white sm:p-8" style={presentationView.heroStyle}>
          {heroImageUrl ? (
            <img
              src={heroImageUrl}
              alt={businessName}
              loading="eager"
              fetchPriority="high"
              decoding="async"
              data-blur={blurDataUrl}
              className={`absolute inset-0 h-full w-full object-cover ${presentationView.isPhotoHeavy ? 'opacity-34' : 'opacity-20'}`}
            />
          ) : null}
          <div className="absolute inset-x-6 bottom-6 top-6 hidden rounded-[30px] border border-white/12 xl:block" style={{ backgroundImage: brand.heroOrnament }} />
          <div className={`relative z-10 flex flex-col gap-5 ${presentationView.headerAlignClassName}`}>
            <div
              className={`flex flex-col gap-6 ${presentationView.isPhotoHeavy ? 'xl:grid xl:grid-cols-[1.25fr_0.75fr]' : 'lg:flex-row lg:items-start lg:justify-between'} ${presentationView.headerAlignClassName}`}
            >
              <div className={`max-w-4xl space-y-4 ${presentationView.headerAlignClassName}`}>
                <div className="flex flex-wrap items-center gap-2">
                  <span className="rounded-full border border-white/15 bg-white/10 px-4 py-2 text-[11px] font-black uppercase tracking-[0.3em] text-white/78">
                    {labels.heroKicker}
                  </span>
                  <span
                    data-testid="brand-mode-badge"
                    className="rounded-full border border-white/15 bg-white/10 px-4 py-2 text-[11px] font-black uppercase tracking-[0.2em] text-white/88"
                  >
                    {brand.label[lang]}
                  </span>
                  {isPreview ? (
                    <span className="rounded-full border border-white/15 bg-white/10 px-4 py-2 text-[11px] font-black uppercase tracking-[0.2em] text-white/88">
                      Preview
                    </span>
                  ) : null}
                  {data.business.is_verified ? (
                    <span className="rounded-full border border-white/15 bg-white/10 px-4 py-2 text-[11px] font-black uppercase tracking-[0.2em] text-white/88">
                      Verified
                    </span>
                  ) : null}
                </div>
                <h1 className="max-w-3xl text-3xl font-black leading-tight sm:text-5xl">{businessName}</h1>
                <p className="max-w-2xl text-sm leading-7 text-white/85 sm:text-base">
                  {data.business.description?.trim() || `${data.menu.title} • ${labels.publicMenu}`}
                </p>
                <p className="max-w-2xl text-xs font-semibold uppercase tracking-[0.2em] text-white/72 sm:text-sm">
                  {labels.heroSummary}
                </p>
              </div>
              {brandLogoUrl ? (
                <div className="relative h-24 w-24 shrink-0 overflow-hidden rounded-[28px] border border-white/20 bg-white/10 shadow-yd2">
                  <img
                    src={brandLogoUrl}
                    alt={`${businessName} logo`}
                    loading="lazy"
                    decoding="async"
                    data-blur={blurDataUrl}
                    className="h-full w-full object-cover"
                  />
                </div>
              ) : null}
            </div>

            <div className="grid gap-4 xl:grid-cols-[1.2fr_0.8fr]">
              <div className="grid gap-3 sm:grid-cols-3">
                <MetricCard label={labels.categoryView} value={String(data.categories.length)} />
                <MetricCard label={labels.resultsCount} value={String(data.items.length)} />
                {presentationView.showLastUpdated ? (
                  <MetricCard label={labels.menuUpdated} value={formatDateLabel(data.menu.updated_at, lang) ?? '-'} />
                ) : null}
              </div>

              <div className="rounded-[28px] border border-white/12 bg-white/10 p-4 backdrop-blur">
                <p className="text-[11px] font-black uppercase tracking-[0.24em] text-white/78">{labels.themePreview}</p>
                <div className="mt-3 flex flex-wrap gap-2">
                  {themeOptions.map((theme) => (
                    <ThemeButton
                      key={theme.id}
                      active={theme.id === brandTheme}
                      onClick={() => handleThemeSelect(theme.id)}
                    >
                      {theme.label}
                    </ThemeButton>
                  ))}
                </div>
              </div>
            </div>

            <div className="flex flex-wrap gap-2">
              {businessLocation ? (
                <span className="rounded-full border border-white/15 bg-white/10 px-4 py-2 text-xs font-bold tracking-[0.18em] text-white/90">
                  {businessLocation}
                </span>
              ) : null}
              <span className="rounded-full border border-white/15 bg-white/10 px-4 py-2 text-xs font-bold tracking-[0.18em] text-white/90">
                {data.menu.title}
              </span>
              {presentationView.showLastUpdated ? (
                <span className="rounded-full border border-white/15 bg-white/10 px-4 py-2 text-xs font-bold tracking-[0.18em] text-white/90">
                  {labels.menuUpdated}: {formatDateLabel(data.menu.updated_at, lang) ?? '-'}
                </span>
              ) : null}
              <span className="rounded-full border border-white/15 bg-white/10 px-4 py-2 text-xs font-bold tracking-[0.18em] text-white/90">
                {labels.categoryJump}: {activeCategoryLabel}
              </span>
            </div>

            <div className="flex flex-wrap gap-3">
              <a
                href={buildQrHref({
                  businessId: data.business.id,
                  lang,
                  theme: brandTheme,
                })}
                className="rounded-2xl bg-white px-5 py-3 text-sm font-black text-primary transition hover:bg-cardAlt"
              >
                {labels.qrTitle}
              </a>
              {data.business.phone ? (
                <a
                  href={`tel:${data.business.phone}`}
                  className="rounded-2xl border border-white/25 px-5 py-3 text-sm font-bold text-white transition hover:bg-white/10"
                >
                  {data.business.phone}
                </a>
              ) : null}
              {data.business.reservation_url ? (
                <a
                  href={data.business.reservation_url}
                  target="_blank"
                  rel="noreferrer"
                  className="rounded-2xl border border-white/25 px-5 py-3 text-sm font-bold text-white transition hover:bg-white/10"
                >
                  Reservation
                </a>
              ) : null}
            </div>
          </div>
        </div>
      </section>

      <section className="sticky top-3 z-30">
        <div className="overflow-hidden rounded-[28px] border border-border bg-card/90 p-3 shadow-yd2 backdrop-blur">
          <div className="flex items-center justify-between gap-3 pb-2">
            <div>
              <p className="text-xs font-black uppercase tracking-[0.24em] text-muted">{labels.categoryView}</p>
              <p className="text-sm font-semibold text-textStrong">{activeCategoryLabel}</p>
            </div>
            <span className="rounded-full bg-primary/10 px-3 py-1 text-xs font-black text-primary">
              {filteredItems.length}
            </span>
          </div>
          <div className="flex gap-2 overflow-x-auto pb-1" role="tablist" aria-label={labels.categoryJump}>
            <PillButton
              active={activeCategoryId === 'all'}
              role="tab"
              ariaSelected={activeCategoryId === 'all'}
              onClick={(event) => handleCategorySelect('all', event.currentTarget)}
            >
              {labels.allCategories}
            </PillButton>
            {categoriesWithLabels.map((category) => (
              <PillButton
                key={category.id}
                active={activeCategoryId === category.id}
                role="tab"
                ariaSelected={activeCategoryId === category.id}
                onClick={(event) => {
                  void trackEvent({
                    eventName: 'category_view',
                    businessId: data.business.id,
                    menuId: data.menu.id,
                    meta: {
                      category_id: category.id,
                      theme: brandTheme,
                      preview: isPreview,
                    },
                  });
                  handleCategorySelect(category.id, event.currentTarget);
                }}
              >
                {category.label}
              </PillButton>
            ))}
          </div>
        </div>
      </section>

      <section className="grid gap-3 md:grid-cols-[1.25fr_0.75fr]">
        <div className="rounded-[28px] border border-border bg-card p-4 shadow-yd1 sm:p-5">
          <label className="mb-3 block text-xs font-black uppercase tracking-[0.24em] text-muted">
            {labels.searchPlaceholder}
          </label>
          <input
            value={query}
            onChange={(event) => setQuery(event.target.value)}
            placeholder={labels.searchPlaceholder}
            className="w-full rounded-2xl border border-border bg-bg px-4 py-3 text-sm text-text outline-none transition focus:border-primary"
            aria-label={labels.searchPlaceholder}
          />
        </div>

        <div className="rounded-[28px] border border-border bg-card p-4 shadow-yd1 sm:p-5">
          <p className="mb-3 text-xs font-black uppercase tracking-[0.24em] text-muted">{labels.filters}</p>
          <div className="grid gap-3 sm:grid-cols-2">
            <div className="rounded-2xl border border-border bg-bg px-4 py-3">
              <p className="text-[11px] font-black uppercase tracking-[0.18em] text-muted">{labels.categoryView}</p>
              <p className="mt-1 text-sm font-semibold text-textStrong">{activeCategoryLabel}</p>
            </div>
            <div className="rounded-2xl border border-border bg-bg px-4 py-3">
              <p className="text-[11px] font-black uppercase tracking-[0.18em] text-muted">{labels.resultsCount}</p>
              <p className="mt-1 text-sm font-semibold text-textStrong">
                {filteredItems.length} / {data.items.length}
              </p>
            </div>
          </div>
        </div>
      </section>

      {presentationView.showFeatured && featuredItems.length > 0 ? (
        <section
          className="overflow-hidden rounded-[30px] border border-border shadow-yd2"
          style={{ backgroundImage: brand.featuredBackground }}
        >
          <div className="grid gap-5 p-4 sm:p-5 xl:grid-cols-[0.42fr_1fr]">
            <div className="rounded-[26px] border border-border bg-card/90 p-5 backdrop-blur" style={{ backgroundImage: brand.featuredAccent }}>
              <p className="text-xs font-black uppercase tracking-[0.24em] text-muted">{labels.curatedSelection}</p>
              <h2 className="mt-2 text-2xl font-black text-textStrong">{businessName}</h2>
              <p className="mt-3 text-sm leading-7 text-text">
                {featuredItems.length} {labels.itemView.toLowerCase()} • {labels.themeMode}: {brand.label[lang]}
              </p>
            </div>
            <div className={`grid gap-3 sm:grid-cols-2 ${presentationView.isPhotoHeavy ? 'xl:grid-cols-2' : 'xl:grid-cols-3'}`}>
              {featuredItems.slice(0, 6).map((item) => (
                <FeatureCard
                  key={`featured-${item.id}`}
                  item={item}
                  lang={lang}
                  data={data}
                  brandTheme={brandTheme}
                  themeDefinition={themeDefinition}
                  blurDataUrl={blurDataUrl}
                />
              ))}
            </div>
          </div>
        </section>
      ) : null}

      <section className="grid gap-6 lg:grid-cols-[0.75fr_1.25fr]">
        <div className="space-y-4">
          <div className="rounded-[28px] border border-border bg-card p-4 shadow-yd1 sm:p-5">
            <p className="text-xs font-black uppercase tracking-[0.24em] text-muted">{labels.menuSections}</p>
            <div className="mt-3 space-y-2">
              {data.sections.map((section) => (
                <div
                  key={section.id}
                  className="rounded-2xl border border-border bg-bg px-4 py-3 text-sm font-semibold text-textStrong"
                >
                  {section.title}
                </div>
              ))}
            </div>
          </div>

          {presentationView.showTags ? (
            <div className="rounded-[28px] border border-border bg-card p-4 shadow-yd1 sm:p-5">
            <div className="flex items-center justify-between gap-3">
              <p className="text-xs font-black uppercase tracking-[0.24em] text-muted">{labels.tags}</p>
              <button
                type="button"
                onClick={() => {
                  setQuery('');
                  handleCategorySelect('all');
                }}
                className="text-xs font-black uppercase tracking-[0.16em] text-primary"
              >
                {labels.clearFilters}
              </button>
            </div>
            <div className="mt-3 flex flex-wrap gap-2">
              {tags.length === 0 ? (
                <span className="text-sm text-muted">{labels.noResultsBody}</span>
              ) : (
                tags.map((tag) => (
                  <button
                    key={tag}
                    type="button"
                    onClick={() => setQuery(tag)}
                    className="rounded-full border border-border bg-bg px-3 py-2 text-xs font-bold uppercase tracking-[0.16em] text-text"
                  >
                    #{tag}
                  </button>
                ))
              )}
            </div>
            </div>
          ) : null}
        </div>

        <section ref={resultsRef} className="space-y-3" aria-label={labels.allItems}>
          {filteredItems.length === 0 ? (
            <div className="rounded-[28px] border border-dashed border-border bg-card p-10 text-center shadow-yd1">
              <h2 className="text-xl font-black text-textStrong">{labels.noResultsTitle}</h2>
              <p className="mt-2 text-sm text-muted">{labels.noResultsBody}</p>
              <button
                type="button"
                onClick={() => {
                  setQuery('');
                  handleCategorySelect('all');
                }}
                className="mt-5 rounded-2xl bg-primary px-5 py-3 text-sm font-black text-white"
              >
                {labels.clearFilters}
              </button>
            </div>
          ) : (
            filteredItems.map((item) => {
              const itemName =
                getTranslationValue({
                  translations: data.translations,
                  entityType: 'item',
                  entityId: item.id,
                  locale: lang,
                  field: 'name',
                  fallback: item.name,
                }) ?? item.name;
              const itemDescription =
                getTranslationValue({
                  translations: data.translations,
                  entityType: 'item',
                  entityId: item.id,
                  locale: lang,
                  field: 'description',
                  fallback: item.description,
                }) ?? item.description;

              return (
                <article
                  key={item.id}
                  className={`group overflow-hidden rounded-[28px] border shadow-yd1 transition ${brand.itemCardClassName}`}
                >
                  <button
                    type="button"
                    aria-label={`${labels.openDetails}: ${itemName}`}
                    aria-haspopup="dialog"
                    onClick={() => {
                      void trackEvent({
                        eventName: 'item_click',
                        businessId: data.business.id,
                        menuId: data.menu.id,
                        meta: {
                          item_id: item.id,
                          theme: brandTheme,
                          preview: isPreview,
                        },
                      });
                      router.push(
                        buildBusinessMenuHref({
                          business: businessPath,
                          itemId: item.id,
                          lang,
                          theme: brandTheme,
                          preview: isPreview,
                        }),
                      );
                    }}
                    className={`grid w-full gap-4 text-left transition-transform active:scale-[0.995] ${presentationView.denseCardClassName} ${
                      presentationView.isPhotoHeavy ? 'lg:grid-cols-[220px_1fr]' : 'sm:grid-cols-[148px_1fr]'
                    }`}
                  >
                    <div className="relative overflow-hidden rounded-[24px] bg-cardAlt">
                      {item.image_url ? (
                        <img
                          src={item.image_url}
                          alt={itemName}
                          loading="lazy"
                          decoding="async"
                          data-blur={blurDataUrl}
                          className={`w-full object-cover transition duration-500 group-hover:scale-[1.04] group-active:scale-[1.01] ${
                            presentationView.isPhotoHeavy ? 'h-44' : 'h-36'
                          }`}
                        />
                      ) : (
                        <div
                          className={`flex items-center justify-center text-xs font-black uppercase tracking-[0.24em] text-muted ${
                            presentationView.isPhotoHeavy ? 'h-44' : 'h-36'
                          }`}
                          style={{ backgroundImage: brand.itemImageFallback }}
                        >
                          {labels.details}
                        </div>
                      )}
                    </div>

                    <div className="flex min-w-0 flex-col gap-3">
                      <div className="flex flex-wrap items-start justify-between gap-3">
                        <div className="min-w-0">
                          <h2 className="truncate text-2xl font-black tracking-[-0.02em] text-textStrong">{itemName}</h2>
                          {itemDescription ? (
                            <p className="mt-1 text-sm leading-7 text-muted">{itemDescription}</p>
                          ) : null}
                        </div>
                        <p
                          className={`rounded-[18px] px-4 py-3 text-base font-black ${brand.itemPriceClassName}`}
                          style={brandTheme === 'dark-modern' ? { color: '#020617' } : undefined}
                        >
                          {formatCurrency(
                            item.price_cents,
                            lang,
                            item.currency,
                            presentationView.showCurrencySymbol,
                          )}
                        </p>
                      </div>

                      <div className="flex flex-wrap gap-2">
                        {!item.is_available ? <Badge>{labels.unavailable}</Badge> : null}
                        {presentationView.showAllergens && item.dietary.isVegan ? <Badge>vegan</Badge> : null}
                        {presentationView.showAllergens && item.dietary.isVegetarian ? <Badge>vegetarian</Badge> : null}
                        {presentationView.showAllergens && item.dietary.isGlutenFree ? <Badge>gluten free</Badge> : null}
                        {presentationView.showAllergens && item.dietary.isLactoseFree ? <Badge>lactose free</Badge> : null}
                        {presentationView.showAllergens && item.dietary.isHalal ? <Badge>halal</Badge> : null}
                        {presentationView.showTags && item.tagList.slice(0, 4).map((tag) => (
                          <Badge key={tag}>#{tag}</Badge>
                        ))}
                      </div>
                    </div>
                  </button>
                </article>
              );
            })
          )}
        </section>
      </section>

      <footer className="rounded-[28px] border border-border bg-card px-5 py-5 shadow-yd1">
        <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
          <p className="text-xs font-black uppercase tracking-[0.24em] text-muted">
            Legal
          </p>
          <div className="flex flex-wrap gap-3">
            {PUBLIC_QR_LEGAL_LINKS.map((item) => (
              <a
                key={item.href}
                href={item.href}
                target="_blank"
                rel="noreferrer"
                className="rounded-full border border-border bg-bg px-4 py-2 text-xs font-black uppercase tracking-[0.16em] text-textStrong transition hover:border-primary/35 hover:text-primary"
              >
                {item.label}
              </a>
            ))}
          </div>
        </div>
      </footer>

      <ItemDetailSheet
        lang={lang}
        labels={labels}
        brandTheme={brandTheme}
        themeDefinition={themeDefinition}
        blurDataUrl={blurDataUrl}
        data={data}
        selectedItemDetails={data.selectedItemDetails}
        open={Boolean(selectedItem)}
        onClose={() =>
          router.push(
            buildBusinessMenuHref({
              business: businessPath,
              categoryId: activeCategoryId !== 'all' ? activeCategoryId : null,
              lang,
              theme: brandTheme,
              preview: isPreview,
            }),
          )
        }
      />
    </div>
  );
}

function FeatureCard({
  item,
  lang,
  data,
  brandTheme,
  themeDefinition,
  blurDataUrl,
}: {
  item: PublicMenuPageData['items'][number];
  lang: AppLang;
  data: PublicMenuPageData;
  brandTheme: BrandTheme;
  themeDefinition: BrandThemeDefinition;
  blurDataUrl: string;
}) {
  const brand = themeDefinition;
  const presentationView = getPresentationViewModel(data.presentation, brandTheme, themeDefinition);
  const name =
    getTranslationValue({
      translations: data.translations,
      entityType: 'item',
      entityId: item.id,
      locale: lang,
      field: 'name',
      fallback: item.name,
    }) ?? item.name;

  return (
    <div className="overflow-hidden rounded-[24px] border border-border bg-cardAlt shadow-yd1 transition hover:-translate-y-1 hover:shadow-yd2">
      {item.image_url ? (
        <img
          src={item.image_url}
          alt={name}
          loading="lazy"
          decoding="async"
          data-blur={blurDataUrl}
          className={`w-full object-cover ${presentationView.isPhotoHeavy ? 'h-52' : 'h-36'}`}
        />
      ) : (
        <div
          className={`${presentationView.isPhotoHeavy ? 'h-52' : 'h-36'} w-full`}
          style={{ backgroundImage: brand.itemImageFallback }}
        />
      )}
      <div className="space-y-2 p-4">
        <p className="text-lg font-black text-textStrong">{name}</p>
        <p className="text-base font-black text-primary">
          {formatCurrency(
            item.price_cents,
            lang,
            item.currency,
            presentationView.showCurrencySymbol,
          )}
        </p>
      </div>
    </div>
  );
}

function Badge({ children }: { children: ReactNode }) {
  return (
    <span className="rounded-full border border-border bg-bg px-3 py-1.5 text-xs font-black uppercase tracking-[0.16em] text-text">
      {children}
    </span>
  );
}

function MetricCard({ label, value }: { label: string; value: string }) {
  return (
    <div className="rounded-[24px] border border-white/12 bg-white/10 px-4 py-4 backdrop-blur">
      <p className="text-[11px] font-black uppercase tracking-[0.2em] text-white/72">{label}</p>
      <p className="mt-2 text-lg font-black text-white">{value}</p>
    </div>
  );
}

function ThemeButton({
  active,
  children,
  onClick,
}: {
  active: boolean;
  children: ReactNode;
  onClick: () => void;
}) {
  return (
    <button
      type="button"
      onClick={onClick}
      className={`rounded-full border px-4 py-2 text-xs font-black uppercase tracking-[0.16em] transition ${
        active ? 'border-white bg-white text-primary' : 'border-white/20 bg-white/10 text-white hover:bg-white/15'
      }`}
    >
      {children}
    </button>
  );
}

function PillButton({
  active,
  children,
  onClick,
  role,
  ariaSelected,
}: {
  active: boolean;
  children: ReactNode;
  onClick: (event: MouseEvent<HTMLButtonElement>) => void;
  role?: 'tab';
  ariaSelected?: boolean;
}) {
  return (
    <button
      type="button"
      role={role}
      aria-selected={ariaSelected}
      tabIndex={ariaSelected === false ? -1 : 0}
      onClick={onClick}
      className={`relative rounded-full border px-4 py-2 text-xs font-black uppercase tracking-[0.16em] transition ${
        active
          ? 'border-primary bg-primary/8 text-primary'
          : 'border-border bg-bg text-textStrong hover:border-primary/35'
      }`}
    >
      <span>{children}</span>
      <span
        aria-hidden="true"
        className={`absolute inset-x-3 bottom-1 h-[2px] origin-center rounded-full bg-primary transition duration-300 ${
          active ? 'scale-x-100 opacity-100' : 'scale-x-0 opacity-0'
        }`}
      />
    </button>
  );
}

async function trackEvent(payload: TrackPayload) {
  try {
    const clientId = getClientId();
    await fetch('/api/track', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      keepalive: true,
      body: JSON.stringify({
        eventName: payload.eventName,
        businessId: payload.businessId,
        menuId: payload.menuId,
        clientId,
        meta: payload.meta ?? {},
      }),
    });
  } catch {
    // Analytics is best-effort only.
  }
}

function getClientId() {
  if (typeof window === 'undefined') return 'server';

  const existing = window.localStorage.getItem('yd_client_id');
  if (existing) return existing;

  const next = `web_${crypto.randomUUID()}`;
  window.localStorage.setItem('yd_client_id', next);
  return next;
}
