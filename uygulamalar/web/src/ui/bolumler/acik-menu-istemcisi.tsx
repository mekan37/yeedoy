'use client';

import Image from 'next/image';
import dynamic from 'next/dynamic';
import type { MouseEvent, ReactNode } from 'react';
import { startTransition, useDeferredValue, useEffect, useRef, useState } from 'react';
import { usePathname, useRouter } from 'next/navigation';
import type { BrandTheme, BrandThemeDefinition } from '@/src/lib/marka-temasi';
import { formatBusinessLocation, formatCurrency, formatDateLabel } from '@/src/lib/bicimlendirme';
import type { AppLang, MenuCopy } from '@/src/lib/ceviri';
import { PUBLIC_QR_LEGAL_LINKS } from '@/src/lib/yasal-baglantilar';
import { buildBusinessMenuHref, buildQrHref } from '@/src/lib/menu-baglantilari';
import { getTranslationValue } from '@/src/lib/menu-metinleri';
import { createSupabaseBrowserClient } from '@/src/lib/taban/istemci';
import { appendMediaVersion, buildMenuImageUrl } from '@/src/lib/medya-adresi';
import { getPresentationViewModel } from '@/src/lib/sunum-gorunumu';
import type { PublicMenuPageData } from '@/src/lib/acik-menu-sayfasi';
import { Search } from 'lucide-react';

const ItemDetailSheet = dynamic(
  () => import('@/src/ui/bolumler/urun-detay-paneli').then((module) => module.MenuItemDetailSheet),
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
  isOpenNow?: boolean | null;
};

type TrackPayload = {
  eventName: 'page_view' | 'category_view' | 'item_view' | 'item_click';
  businessId: string;
  menuId: string;
  meta?: Record<string, unknown>;
};

const ALLERGEN_LIST: Array<{ code: string; labelTr: string; labelEn: string }> = [
  { code: 'gluten',        labelTr: 'Gluten',                    labelEn: 'Gluten' },
  { code: 'crustaceans',   labelTr: 'Kabuklu Deniz Ürünleri',   labelEn: 'Crustaceans' },
  { code: 'egg',           labelTr: 'Yumurta',                   labelEn: 'Egg' },
  { code: 'fish',          labelTr: 'Balık',                     labelEn: 'Fish' },
  { code: 'peanuts',       labelTr: 'Yer Fıstığı',               labelEn: 'Peanuts' },
  { code: 'soy',           labelTr: 'Soya',                      labelEn: 'Soy' },
  { code: 'milk',          labelTr: 'Süt',                       labelEn: 'Milk' },
  { code: 'treenuts',      labelTr: 'Sert Kabuklu Yemişler',     labelEn: 'Tree nuts' },
  { code: 'celery',        labelTr: 'Kereviz',                   labelEn: 'Celery' },
  { code: 'mustard',       labelTr: 'Hardal',                    labelEn: 'Mustard' },
  { code: 'sesame',        labelTr: 'Susam',                     labelEn: 'Sesame' },
  { code: 'sulfur_dioxide',labelTr: 'Kükürt Dioksit',            labelEn: 'Sulphur dioxide' },
  { code: 'lupin',         labelTr: 'Acı Bakla',                 labelEn: 'Lupin' },
  { code: 'molluscs',      labelTr: 'Yumuşakçalar',              labelEn: 'Molluscs' },
];

export function AcikMenuIstemcisi({
  lang,
  labels,
  brandTheme,
  themeDefinition,
  themeOptions,
  blurDataUrl,
  data,
  isPreview,
  selectedCategoryId,
  isOpenNow,
}: Props) {
  const router = useRouter();
  const pathname = usePathname();
  const resultsRef = useRef<HTMLElement | null>(null);
  const brand = themeDefinition;
  const presentationView = getPresentationViewModel(data.presentation, brandTheme, themeDefinition);
  const [query, setQuery] = useState('');
  const [activeCategoryId, setActiveCategoryId] = useState(selectedCategoryId ?? 'all');
  // Realtime availability overrides: itemId → is_available
  const [availabilityMap, setAvailabilityMap] = useState<Record<string, boolean>>({});
  // Allergen filter: codes to exclude (items containing any of these are hidden)
  const [excludeAllergens, setExcludeAllergens] = useState<Set<string>>(new Set());
  const [allergenMenuOpen, setAllergenMenuOpen] = useState(false);
  const deferredQuery = useDeferredValue(query);
  const selectedItem = data.selectedItem;
  const businessPath = data.business;
  const businessLocation = formatBusinessLocation(data.business);
  const mediaVersion = data.presentation.updatedAt;
  const heroImageUrl = buildMenuImageUrl(
    appendMediaVersion(data.presentation.backgroundUrl || data.media.coverUrl, mediaVersion),
    { width: 1400, quality: 85 },
  );
  const brandLogoUrl = buildMenuImageUrl(
    appendMediaVersion(data.media.logoUrl, mediaVersion),
    { width: 200, quality: 90 },
  );
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

  // Close allergen dropdown on outside click
  useEffect(() => {
    if (!allergenMenuOpen) return;
    const handler = () => setAllergenMenuOpen(false);
    document.addEventListener('click', handler, { capture: true, once: true });
    return () => document.removeEventListener('click', handler, { capture: true });
  }, [allergenMenuOpen]);

  // Realtime stock subscription
  useEffect(() => {
    if (isPreview) return;
    const supabase = createSupabaseBrowserClient();
    const channel = supabase
      .channel(`menu-items-availability-${data.menu.id}`)
      .on(
        'postgres_changes',
        {
          event: 'UPDATE',
          schema: 'public',
          table: 'menu_items',
          filter: `menu_id=eq.${data.menu.id}`,
        },
        (payload: { new: Record<string, unknown> }) => {
          const updated = payload.new;
          if (typeof updated.id === 'string' && typeof updated.is_available === 'boolean') {
            setAvailabilityMap((prev) => ({ ...prev, [updated.id as string]: updated.is_available as boolean }));
          }
        },
      )
      .subscribe();

    return () => {
      void supabase.removeChannel(channel);
    };
  }, [data.menu.id, isPreview]);

  const filteredItems = data.items.filter((item) => {
    if (activeCategoryId !== 'all' && item.category_id !== activeCategoryId) return false;
    // Hide items containing excluded allergens
    if (excludeAllergens.size > 0 && item.allergens.some((a) => excludeAllergens.has(a))) return false;
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

  function handleLangSelect(nextLang: 'tr' | 'en') {
    const params = new URLSearchParams();
    params.set('lang', nextLang);
    params.set('theme', brandTheme);
    if (isPreview) params.set('preview', '1');
    startTransition(() => {
      router.push(`${pathname}?${params.toString()}`);
    });
  }

  async function handleShare() {
    const shareUrl = typeof window !== 'undefined' ? window.location.href : '';
    const shareData = {
      title: businessName,
      text: `${businessName} menüsüne göz at`,
      url: shareUrl,
    };
    if (typeof navigator !== 'undefined' && 'share' in navigator) {
      try {
        await navigator.share(shareData);
        return;
      } catch {
        // fallthrough to clipboard
      }
    }
    if (typeof navigator !== 'undefined' && navigator.clipboard) {
      await navigator.clipboard.writeText(shareUrl);
    }
  }

  return (
    <div
      className={`space-y-6 rounded-[36px] p-3 pb-10 sm:p-4 ${presentationView.fontScaleClassName}`}
      style={presentationView.pageStyle}
    >
      <section className="overflow-hidden rounded-[32px] border border-border bg-card shadow-yd2">
        <div className="relative min-h-[340px] overflow-hidden p-6 text-white sm:p-8" style={presentationView.heroStyle}>
          {heroImageUrl ? (
            <Image
              src={heroImageUrl}
              alt={businessName}
              fill
              priority
              unoptimized
              placeholder="blur"
              blurDataURL={blurDataUrl}
              className={`object-cover ${presentationView.isPhotoHeavy ? 'opacity-34' : 'opacity-20'}`}
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
                  {isOpenNow === true ? (
                    <span className="flex items-center gap-1.5 rounded-full border border-emerald-400/30 bg-emerald-500/15 px-4 py-2 text-[11px] font-black uppercase tracking-[0.2em] text-emerald-300">
                      <span className="inline-block h-1.5 w-1.5 rounded-full bg-emerald-400" />
                      {labels.openNow}
                    </span>
                  ) : isOpenNow === false ? (
                    <span className="flex items-center gap-1.5 rounded-full border border-white/15 bg-white/10 px-4 py-2 text-[11px] font-black uppercase tracking-[0.2em] text-white/60">
                      <span className="inline-block h-1.5 w-1.5 rounded-full bg-white/40" />
                      {labels.closedNow}
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
                  <Image
                    src={brandLogoUrl}
                    alt={`${businessName} logo`}
                    fill
                    unoptimized
                    placeholder="blur"
                    blurDataURL={blurDataUrl}
                    className="object-cover"
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
              <button
                type="button"
                onClick={() => void handleShare()}
                className="rounded-2xl border border-white/25 px-5 py-3 text-sm font-bold text-white transition hover:bg-white/10"
                aria-label={lang === 'tr' ? 'Paylaş' : 'Share'}
              >
                {lang === 'tr' ? 'Paylaş' : 'Share'}
              </button>
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
                  {lang === 'tr' ? 'Rezervasyon' : 'Reservation'}
                </a>
              ) : null}
              {data.socialLinks?.whatsapp ? (
                <a
                  href={`https://wa.me/${data.socialLinks.whatsapp.replace(/\D/g, '')}`}
                  target="_blank"
                  rel="noreferrer"
                  className="rounded-2xl border border-white/25 px-5 py-3 text-sm font-bold text-white transition hover:bg-white/10"
                >
                  WhatsApp
                </a>
              ) : null}
              {data.socialLinks?.instagram ? (
                <a
                  href={data.socialLinks.instagram}
                  target="_blank"
                  rel="noreferrer"
                  className="rounded-2xl border border-white/25 px-5 py-3 text-sm font-bold text-white transition hover:bg-white/10"
                >
                  Instagram
                </a>
              ) : null}
              {data.socialLinks?.website ? (
                <a
                  href={data.socialLinks.website}
                  target="_blank"
                  rel="noreferrer"
                  className="rounded-2xl border border-white/25 px-5 py-3 text-sm font-bold text-white transition hover:bg-white/10"
                >
                  {lang === 'tr' ? 'Website' : 'Website'}
                </a>
              ) : null}
            </div>
          </div>
        </div>
      </section>

      <section className="sticky top-3 z-30">
        <div className="overflow-hidden rounded-[28px] border border-border bg-card/92 p-3 shadow-yd2 backdrop-blur-md">
          {/* Mobile-only search input inside sticky bar */}
          <div className="mb-2 md:hidden">
            <input
              value={query}
              onChange={(event) => setQuery(event.target.value)}
              placeholder={labels.searchPlaceholder}
              className="w-full rounded-2xl border border-border bg-bg px-4 py-2.5 text-sm text-text outline-none transition focus:border-primary"
              aria-label={labels.searchPlaceholder}
            />
          </div>
          <div className="flex items-center justify-between gap-3 pb-2">
            <div>
              <p className="text-xs font-black uppercase tracking-[0.24em] text-muted">{labels.categoryView}</p>
              <p className="text-sm font-semibold text-textStrong">{activeCategoryLabel}</p>
            </div>
            <div className="flex shrink-0 items-center gap-2">
              <span className="rounded-full bg-primary/10 px-3 py-1 text-xs font-black text-primary">
                {filteredItems.length}
              </span>
              <div className="flex rounded-full border border-border bg-bg p-0.5" role="group" aria-label="Language">
                {(['tr', 'en'] as const).map((l) => (
                  <button
                    key={l}
                    type="button"
                    onClick={() => handleLangSelect(l)}
                    className={`rounded-full px-2.5 py-1 text-xs font-black uppercase transition ${lang === l ? 'bg-primary text-white' : 'text-muted hover:text-text'}`}
                    aria-pressed={lang === l}
                  >
                    {l.toUpperCase()}
                  </button>
                ))}
              </div>
              {/* Allergen filter */}
              <div className="relative">
                <button
                  type="button"
                  onClick={() => setAllergenMenuOpen((v) => !v)}
                  className={`flex items-center gap-1.5 rounded-full border px-3 py-1.5 text-xs font-black transition ${excludeAllergens.size > 0 ? 'border-primary bg-primary/10 text-primary' : 'border-border bg-bg text-muted hover:text-text'}`}
                  aria-expanded={allergenMenuOpen}
                >
                  {lang === 'tr' ? 'Alerjen' : 'Allergen'}
                  {excludeAllergens.size > 0 ? ` (${excludeAllergens.size})` : ''}
                </button>
                {allergenMenuOpen ? (
                  <div className="absolute right-0 top-full z-50 mt-1 max-h-64 w-52 overflow-y-auto rounded-2xl border border-border bg-card p-2 shadow-yd2">
                    <p className="mb-1 px-2 text-[10px] font-black uppercase tracking-widest text-muted">
                      {lang === 'tr' ? 'Alerjen hariç tut' : 'Exclude allergens'}
                    </p>
                    {ALLERGEN_LIST.map(({ code, labelTr, labelEn }) => (
                      <label
                        key={code}
                        className="flex cursor-pointer items-center gap-2 rounded-xl px-2 py-1.5 hover:bg-bg"
                      >
                        <input
                          type="checkbox"
                          checked={excludeAllergens.has(code)}
                          onChange={() => {
                            setExcludeAllergens((prev) => {
                              const next = new Set(prev);
                              if (next.has(code)) next.delete(code);
                              else next.add(code);
                              return next;
                            });
                          }}
                          className="accent-primary"
                        />
                        <span className="text-xs font-semibold text-text">
                          {lang === 'tr' ? labelTr : labelEn}
                        </span>
                      </label>
                    ))}
                    {excludeAllergens.size > 0 ? (
                      <button
                        type="button"
                        onClick={() => setExcludeAllergens(new Set())}
                        className="mt-1 w-full rounded-xl px-2 py-1 text-xs font-black text-danger hover:bg-danger/10"
                      >
                        {lang === 'tr' ? 'Temizle' : 'Clear'}
                      </button>
                    ) : null}
                  </div>
                ) : null}
              </div>
            </div>
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
                  const nextId = activeCategoryId === category.id ? 'all' : category.id;
                  if (nextId !== 'all') {
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
                  }
                  handleCategorySelect(nextId, event.currentTarget);
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
        <div className="space-y-4 lg:sticky lg:top-6 lg:self-start lg:max-h-[85vh] lg:overflow-y-auto">
          {/* ── Category jump nav (desktop sticky sidebar) ─────────────── */}
          <div className="rounded-[28px] border border-border bg-card p-4 shadow-yd1 sm:p-5">
            <div className="flex items-center justify-between gap-2 mb-3">
              <p className="text-xs font-black uppercase tracking-[0.24em] text-muted">{labels.menuSections}</p>
              {activeCategoryId !== 'all' ? (
                <button
                  type="button"
                  onClick={() => handleCategorySelect('all')}
                  className="text-xs font-black uppercase tracking-[0.14em] text-primary"
                >
                  {labels.clearFilters}
                </button>
              ) : null}
            </div>
            <nav aria-label={labels.categoryJump}>
              <ul className="space-y-1">
                {categoriesWithLabels.map((category) => {
                  const count = data.items.filter((i) => i.category_id === category.id).length;
                  const isActive = activeCategoryId === category.id;
                  return (
                    <li key={category.id}>
                      <button
                        type="button"
                        onClick={(event) => {
                          const nextId = isActive ? 'all' : category.id;
                          handleCategorySelect(nextId, event.currentTarget);
                        }}
                        className={`flex w-full items-center justify-between rounded-2xl px-3 py-2.5 text-left text-sm transition ${
                          isActive
                            ? 'border-l-2 border-primary bg-primary/10 pl-[10px] font-black text-primary'
                            : 'font-semibold text-text hover:bg-bg'
                        }`}
                        aria-pressed={isActive}
                      >
                        <span className="truncate">{category.label}</span>
                        <span className={`ml-2 shrink-0 rounded-full px-2 py-0.5 text-[10px] font-black ${isActive ? 'bg-primary/20 text-primary' : 'bg-bg text-muted'}`}>
                          {count}
                        </span>
                      </button>
                    </li>
                  );
                })}
              </ul>
            </nav>
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

        <section ref={resultsRef} aria-label={labels.allItems}>
          {filteredItems.length === 0 ? (
            <div className="rounded-[28px] border border-dashed border-border bg-card p-10 text-center shadow-yd1">
              <div
                className="mx-auto mb-5 flex size-20 items-center justify-center rounded-full"
                style={{ background: 'radial-gradient(circle, rgba(127,29,29,0.10), rgba(127,29,29,0.04))' }}
                aria-hidden="true"
              >
                <Search className="h-8 w-8 text-primary" aria-hidden="true" />
              </div>
              <h2 className="text-xl font-black tracking-tight text-textStrong">{labels.noResultsTitle}</h2>
              <p className="mx-auto mt-2 max-w-xs text-sm leading-relaxed text-muted">{labels.noResultsBody}</p>
              <button
                type="button"
                onClick={() => {
                  setQuery('');
                  handleCategorySelect('all');
                }}
                className="btn-primary mt-6 inline-flex items-center gap-2 rounded-2xl px-5 py-3 text-sm font-black text-white"
              >
                {labels.clearFilters}
              </button>
            </div>
          ) : (
            <ul role="list" className="space-y-3">
            {filteredItems.map((item) => {
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
                <li
                  key={item.id}
                  role="listitem"
                  className={`card-interactive group relative overflow-hidden rounded-[28px] border shadow-yd1 ${brand.itemCardClassName} ${!(availabilityMap[item.id] ?? item.is_available) ? 'opacity-60' : ''}`}
                >
                  {/* Left accent bar — slides in on hover */}
                  <div
                    className="pointer-events-none absolute bottom-0 left-0 top-0 z-10 w-[3px] rounded-l-[28px] opacity-0 transition-opacity duration-200 group-hover:opacity-100"
                    style={{ background: 'var(--yd-gradient-primary)' }}
                    aria-hidden="true"
                  />
                  {!(availabilityMap[item.id] ?? item.is_available) ? (
                    <div className="pointer-events-none absolute inset-0 z-10 flex items-center justify-center rounded-[28px] bg-black/30 backdrop-blur-[1px]">
                      <span className="rounded-full border border-white/30 bg-black/60 px-5 py-2 text-xs font-black uppercase tracking-[0.2em] text-white">
                        {labels.soldOut}
                      </span>
                    </div>
                  ) : null}
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
                    <div
                      className={`relative overflow-hidden rounded-[24px] bg-cardAlt ${
                        presentationView.isPhotoHeavy ? 'h-44' : 'h-36'
                      }`}
                    >
                      {item.image_url ? (
                        <Image
                          src={buildMenuImageUrl(item.image_url, { width: 480, quality: 80 }) ?? item.image_url}
                          alt={itemName}
                          fill
                          unoptimized
                          placeholder="blur"
                          blurDataURL={blurDataUrl}
                          className="object-cover transition duration-500 group-hover:scale-[1.04] group-active:scale-[1.01]"
                        />
                      ) : (
                        <div
                          className="flex h-full items-center justify-center text-xs font-black uppercase tracking-[0.24em] text-muted"
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
                        {presentationView.showAllergens && item.dietary.isVegan ? <Badge>vegan</Badge> : null}
                        {presentationView.showAllergens && item.dietary.isVegetarian ? <Badge>vegetarian</Badge> : null}
                        {presentationView.showAllergens && item.dietary.isGlutenFree ? <Badge>gluten free</Badge> : null}
                        {presentationView.showAllergens && item.dietary.isLactoseFree ? <Badge>lactose free</Badge> : null}
                        {presentationView.showAllergens && item.dietary.isHalal ? <Badge>halal</Badge> : null}
                        {presentationView.showTags && item.tagList.slice(0, 4).map((tag) => (
                          <Badge key={tag}>#{tag}</Badge>
                        ))}
                      </div>
                      {presentationView.showAllergens && item.allergens.length > 0 ? (
                        <AllergenIconRow allergens={item.allergens} lang={lang} />
                      ) : null}
                    </div>
                  </button>
                </li>
              );
            })}
            </ul>
          )}
        </section>
      </section>

      <footer className="rounded-[28px] border border-border bg-card px-5 py-5 shadow-yd1">
        {(data.socialLinks?.website || data.socialLinks?.instagram || data.socialLinks?.facebook || data.socialLinks?.tiktok || data.socialLinks?.whatsapp || data.business.lat) ? (
          <div className="mb-4 flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between border-b border-border pb-4">
            <p className="text-xs font-black uppercase tracking-[0.24em] text-muted">
              {lang === 'tr' ? 'İletişim' : 'Contact'}
            </p>
            <div className="flex flex-wrap gap-2">
              {data.business.lat && data.business.lng ? (
                <a
                  href={`https://www.google.com/maps/arama/?api=1&query=${data.business.lat},${data.business.lng}`}
                  target="_blank"
                  rel="noreferrer"
                  className="rounded-full border border-border bg-bg px-4 py-2 text-xs font-black uppercase tracking-[0.16em] text-textStrong transition hover:border-primary/35 hover:text-primary"
                >
                  {lang === 'tr' ? 'Harita' : 'Maps'}
                </a>
              ) : null}
              {data.socialLinks?.whatsapp ? (
                <a
                  href={`https://wa.me/${data.socialLinks.whatsapp.replace(/\D/g, '')}`}
                  target="_blank"
                  rel="noreferrer"
                  className="rounded-full border border-border bg-bg px-4 py-2 text-xs font-black uppercase tracking-[0.16em] text-textStrong transition hover:border-primary/35 hover:text-primary"
                >
                  WhatsApp
                </a>
              ) : null}
              {data.socialLinks?.instagram ? (
                <a
                  href={data.socialLinks.instagram}
                  target="_blank"
                  rel="noreferrer"
                  className="rounded-full border border-border bg-bg px-4 py-2 text-xs font-black uppercase tracking-[0.16em] text-textStrong transition hover:border-primary/35 hover:text-primary"
                >
                  Instagram
                </a>
              ) : null}
              {data.socialLinks?.facebook ? (
                <a
                  href={data.socialLinks.facebook}
                  target="_blank"
                  rel="noreferrer"
                  className="rounded-full border border-border bg-bg px-4 py-2 text-xs font-black uppercase tracking-[0.16em] text-textStrong transition hover:border-primary/35 hover:text-primary"
                >
                  Facebook
                </a>
              ) : null}
              {data.socialLinks?.tiktok ? (
                <a
                  href={data.socialLinks.tiktok}
                  target="_blank"
                  rel="noreferrer"
                  className="rounded-full border border-border bg-bg px-4 py-2 text-xs font-black uppercase tracking-[0.16em] text-textStrong transition hover:border-primary/35 hover:text-primary"
                >
                  TikTok
                </a>
              ) : null}
              {data.socialLinks?.website ? (
                <a
                  href={data.socialLinks.website}
                  target="_blank"
                  rel="noreferrer"
                  className="rounded-full border border-border bg-bg px-4 py-2 text-xs font-black uppercase tracking-[0.16em] text-textStrong transition hover:border-primary/35 hover:text-primary"
                >
                  {lang === 'tr' ? 'Website' : 'Website'}
                </a>
              ) : null}
            </div>
          </div>
        ) : null}
        {data.business.lat && data.business.lng ? (
          <StaticMapBlock
            lat={data.business.lat}
            lng={data.business.lng}
            label={data.business.name}
          />
        ) : null}
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
    <div className="card-interactive overflow-hidden rounded-[24px] border border-border bg-cardAlt shadow-yd1">
      <div
        className={`relative w-full ${presentationView.isPhotoHeavy ? 'h-52' : 'h-36'}`}
      >
        {item.image_url ? (
          <Image
            src={buildMenuImageUrl(item.image_url, { width: 600, quality: 80 }) ?? item.image_url}
            alt={name}
            fill
            unoptimized
            placeholder="blur"
            blurDataURL={blurDataUrl}
            className="object-cover"
          />
        ) : (
          <div
            className="h-full w-full"
            style={{ backgroundImage: brand.itemImageFallback }}
          />
        )}
      </div>
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

// Top-5 allergens shown as icons on item cards (M6)
const TOP5_ALLERGENS: Array<{ code: string; emoji: string; labelTr: string; labelEn: string }> = [
  { code: 'gluten',   emoji: '🌾', labelTr: 'Gluten',       labelEn: 'Gluten' },
  { code: 'milk',     emoji: '🥛', labelTr: 'Süt',          labelEn: 'Milk' },
  { code: 'egg',      emoji: '🥚', labelTr: 'Yumurta',      labelEn: 'Egg' },
  { code: 'peanuts',  emoji: '🥜', labelTr: 'Yer Fıstığı',  labelEn: 'Peanuts' },
  { code: 'treenuts', emoji: '🌰', labelTr: 'Kuruyemiş',    labelEn: 'Tree nuts' },
];

function AllergenIconRow({ allergens, lang }: { allergens: string[]; lang: AppLang }) {
  const set = new Set(allergens);
  const present = TOP5_ALLERGENS.filter((a) => set.has(a.code));
  if (present.length === 0) return null;
  return (
    <div className="flex flex-wrap items-center gap-1.5">
      <span className="text-[10px] font-black uppercase tracking-[0.14em] text-muted">
        {lang === 'tr' ? 'Alerjen:' : 'Contains:'}
      </span>
      {present.map((a) => (
        <span
          key={a.code}
          title={lang === 'tr' ? a.labelTr : a.labelEn}
          aria-label={lang === 'tr' ? a.labelTr : a.labelEn}
          className="cursor-default text-base leading-none"
        >
          {a.emoji}
        </span>
      ))}
    </div>
  );
}

// T1: Google Maps static thumbnail — shows when NEXT_PUBLIC_GMAPS_KEY is set,
// falls back gracefully (no img rendered, existing "Harita" text link stays).
function StaticMapBlock({ lat, lng, label }: { lat: number; lng: number; label: string }) {
  const apiKey = process.env.NEXT_PUBLIC_GMAPS_KEY;
  const mapsUrl = `https://www.google.com/maps/arama/?api=1&query=${lat},${lng}`;
  if (!apiKey) return null;
  const src = `https://maps.googleapis.com/maps/api/staticmap?center=${lat},${lng}&zoom=15&size=480x200&markers=color:red%7C${lat},${lng}&key=${apiKey}`;
  return (
    <a
      href={mapsUrl}
      target="_blank"
      rel="noreferrer"
      className="mb-4 block overflow-hidden rounded-2xl border border-border"
      aria-label={label}
    >
      {/* eslint-disable-next-line @next/next/no-img-element */}
      <img
        src={src}
        alt={label}
        width={480}
        height={200}
        className="w-full object-cover"
        loading="lazy"
      />
    </a>
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
      className={`relative shrink-0 overflow-hidden rounded-full border px-4 py-2 text-xs font-black uppercase tracking-[0.16em] transition-all duration-200 ${
        active
          ? 'border-transparent text-white shadow-[0_2px_12px_rgba(127,29,29,0.35)]'
          : 'border-border bg-bg text-textStrong hover:border-primary/35 hover:text-primary'
      }`}
    >
      {/* Gradient overlay — always present, opacity transitions */}
      <span
        className={`absolute inset-0 transition-opacity duration-200 ${active ? 'opacity-100' : 'opacity-0'}`}
        style={{ background: 'linear-gradient(135deg,#7F1D1D 0%,#DC2626 100%)' }}
        aria-hidden="true"
      />
      <span className="relative z-10">{children}</span>
    </button>
  );
}

async function trackEvent(payload: TrackPayload) {
  try {
    const clientId = getClientId();
    await fetch('/sunucu/izleme', {
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
