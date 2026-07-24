'use client';

import Image from 'next/image';
import { useEffect, useRef, type ReactNode } from 'react';
import { Flame } from 'lucide-react';

const ALLERGEN_LIST = [
  { code: 'gluten',         labelTr: 'Gluten',                      labelEn: 'Gluten'          },
  { code: 'crustaceans',    labelTr: 'Kabuklu Deniz Ürünleri',      labelEn: 'Crustaceans'     },
  { code: 'egg',            labelTr: 'Yumurta',                     labelEn: 'Egg'             },
  { code: 'fish',           labelTr: 'Balık',                       labelEn: 'Fish'            },
  { code: 'peanuts',        labelTr: 'Yer Fıstığı',                 labelEn: 'Peanuts'         },
  { code: 'soy',            labelTr: 'Soya',                        labelEn: 'Soy'             },
  { code: 'milk',           labelTr: 'Süt',                         labelEn: 'Milk'            },
  { code: 'treenuts',       labelTr: 'Sert Kabuklu Yemişler',       labelEn: 'Tree nuts'       },
  { code: 'celery',         labelTr: 'Kereviz',                     labelEn: 'Celery'          },
  { code: 'mustard',        labelTr: 'Hardal',                      labelEn: 'Mustard'         },
  { code: 'sesame',         labelTr: 'Susam',                       labelEn: 'Sesame'          },
  { code: 'sulfur_dioxide', labelTr: 'Kükürt Dioksit / Sülfitler',  labelEn: 'Sulphur dioxide' },
  { code: 'lupin',          labelTr: 'Acı Bakla',                   labelEn: 'Lupin'           },
  { code: 'molluscs',       labelTr: 'Yumuşakçalar',                labelEn: 'Molluscs'        },
] as const;
import type { BrandTheme, BrandThemeDefinition } from '@/src/lib/brand-theme';
import { formatCurrency } from '@/src/lib/format';
import type { AppLang, MenuCopy } from '@/src/lib/i18n';
import { buildMenuImageUrl } from '@/src/lib/media-url';
import { getTranslationValue } from '@/src/lib/menu-text';
import { getPresentationViewModel } from '@/src/lib/presentation-view';
import type { SelectedItemDetails } from '@/src/lib/public-menu-page';
import type { PublicMenuPageData } from '@/src/lib/public-menu-page';
import type { PriceHistoryEntry } from '@/src/lib/db/menu-read';

type Props = {
  lang: AppLang;
  labels: MenuCopy;
  brandTheme: BrandTheme;
  themeDefinition: BrandThemeDefinition;
  blurDataUrl: string;
  data: PublicMenuPageData;
  selectedItemDetails: SelectedItemDetails | null;
  open: boolean;
  onClose: () => void;
};

export function MenuItemDetailSheet({
  lang,
  labels,
  brandTheme,
  themeDefinition,
  blurDataUrl,
  data,
  selectedItemDetails,
  open,
  onClose,
}: Props) {
  const closeButtonRef = useRef<HTMLButtonElement | null>(null);
  const item = data.selectedItem;
  const presentationView = getPresentationViewModel(data.presentation, brandTheme, themeDefinition);

  useEffect(() => {
    if (!open) return;
    closeButtonRef.current?.focus();

    function handleKeyDown(event: KeyboardEvent) {
      if (event.key === 'Escape') onClose();
    }

    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [onClose, open]);

  if (!open || !item) return null;

  const title =
    getTranslationValue({
      translations: data.translations,
      entityType: 'item',
      entityId: item.id,
      locale: lang,
      field: 'name',
      fallback: item.name,
    }) ?? item.name;
  const description =
    getTranslationValue({
      translations: data.translations,
      entityType: 'item',
      entityId: item.id,
      locale: lang,
      field: 'description',
      fallback: item.description,
    }) ?? item.description;

  return (
    <div className="fixed inset-0 z-50 flex items-end justify-center p-0 sm:p-6">
      <button
        type="button"
        aria-label={labels.closeDetails}
        className="animate-overlay-in absolute inset-0 bg-slate-950/45"
        onClick={onClose}
      />
      <div
        role="dialog"
        aria-modal="true"
        aria-labelledby="menu-item-sheet-title"
        aria-describedby="menu-item-sheet-description"
        className="animate-sheet-in relative max-h-[92vh] w-full max-w-3xl overflow-y-auto rounded-t-[32px] border border-border bg-card shadow-yd3 sm:rounded-[32px]"
      >
        <div className="sticky top-0 z-10 flex items-center justify-between border-b border-border bg-card/95 px-5 py-4 backdrop-blur-sm">
          <div>
            <p className="text-xs font-black uppercase tracking-[0.2em] text-muted">{labels.details}</p>
            <h2 id="menu-item-sheet-title" className="text-xl font-black text-textStrong">
              {title}
            </h2>
          </div>
          <button
            ref={closeButtonRef}
            type="button"
            onClick={onClose}
            className="rounded-2xl border border-border bg-bg px-4 py-2 text-sm font-black text-textStrong"
          >
            {labels.close}
          </button>
        </div>

        <div className="space-y-5 p-5">
          <div className="grid gap-4 md:grid-cols-[1fr_0.9fr]">

            <div className="space-y-4">
              {item.image_url ? (
                <div className="relative aspect-16/10 overflow-hidden rounded-[28px] bg-cardAlt">
                  <Image
                    src={buildMenuImageUrl(item.image_url, { width: 900, quality: 85 }) ?? item.image_url}
                    alt={title}
                    fill
                    priority
                    unoptimized
                    placeholder="blur"
                    blurDataURL={blurDataUrl}
                    className="object-cover"
                  />
                </div>
              ) : (
                <div
                  className="h-64 rounded-[28px]"
                  style={{ backgroundImage: themeDefinition.itemImageFallback }}
                />
              )}
              {description ? (
                <p id="menu-item-sheet-description" className="text-sm leading-7 text-text">
                  {description}
                </p>
              ) : null}
              <div className="flex flex-wrap gap-2">
                <Badge>
                  {formatCurrency(
                    item.price_cents,
                    lang,
                    item.currency,
                    presentationView.showCurrencySymbol,
                  )}
                </Badge>
                {presentationView.showAllergens && item.dietary.isVegan ? <Badge>vegan</Badge> : null}
                {presentationView.showAllergens && item.dietary.isVegetarian ? <Badge>vegetarian</Badge> : null}
                {presentationView.showAllergens && item.dietary.isGlutenFree ? <Badge>gluten free</Badge> : null}
                {presentationView.showAllergens && item.dietary.isLactoseFree ? <Badge>lactose free</Badge> : null}
                {presentationView.showAllergens && item.dietary.isHalal ? <Badge>halal</Badge> : null}
                {presentationView.showTags && item.tagList.map((tag) => <Badge key={tag}>#{tag}</Badge>)}
              </div>
            </div>

            <div className="space-y-4">
              <div className="rounded-[28px] border border-border bg-bg p-4">
                <p className="text-xs font-black uppercase tracking-[0.2em] text-muted">{labels.variants}</p>
                <div className="mt-3 space-y-2">
                  {(selectedItemDetails?.variants.length ?? 0) === 0 ? (
                    <p className="text-sm text-muted">{labels.noResultsBody}</p>
                  ) : (
                    selectedItemDetails?.variants.map((variant) => (
                      <div
                        key={variant.id}
                        className="flex items-center justify-between rounded-2xl border border-border bg-card px-4 py-3 text-sm"
                      >
                        <span className="font-semibold text-textStrong">{variant.label}</span>
                        <span className="font-black text-primary">
                          {formatCurrency(
                            variant.price_cents,
                            lang,
                            variant.currency,
                            presentationView.showCurrencySymbol,
                          )}
                        </span>
                      </div>
                    ))
                  )}
                </div>
              </div>

              <div className="rounded-[28px] border border-border bg-bg p-4">
                <p className="text-xs font-black uppercase tracking-[0.2em] text-muted">{labels.photos}</p>
                <div className="mt-3 grid grid-cols-2 gap-3">
                  {(selectedItemDetails?.photos.length ?? 0) === 0 ? (
                    <p className="col-span-2 text-sm text-muted">{labels.noResultsBody}</p>
                  ) : (
                    selectedItemDetails?.photos.map((photo) => (
                      <div key={photo.id} className="relative h-28 overflow-hidden rounded-2xl bg-card">
                        <Image
                          src={photo.url_thumb || photo.url_large || photo.url}
                          alt={title}
                          fill
                          unoptimized
                          placeholder="blur"
                          blurDataURL={blurDataUrl}
                          className="object-cover"
                        />
                      </div>
                    ))
                  )}
                </div>
              </div>

              {selectedItemDetails?.priceHistory.some((entry) => entry.old_price_cents !== null) ||
              (selectedItemDetails?.priceHistory.length ?? 0) > 1 ? (
                <div className="rounded-[28px] border border-border bg-bg p-4">
                  <p className="mb-3 text-xs font-black uppercase tracking-[0.2em] text-muted">
                    {labels.priceHistory}
                  </p>
                  <PriceSparkline
                    entries={selectedItemDetails?.priceHistory ?? []}
                    lang={lang}
                    showCurrencySymbol={presentationView.showCurrencySymbol}
                  />
                </div>
              ) : null}
            </div>
          </div>

          {(item.calories_min != null || item.ingredients.length > 0) && (
            <div className="rounded-2xl border border-border bg-bg p-4 space-y-3">
              <p className="text-[10px] font-black uppercase tracking-widest text-muted">
                {lang === 'tr' ? 'Şeffaf Menü' : 'Transparent Menu'}
              </p>

              {item.calories_min != null && (
                <div className="flex items-center gap-2">
                  <Flame size={16} className="text-primary shrink-0" aria-hidden="true" />
                  <span className="text-sm font-extrabold text-textStrong">
                    {item.calories_min} kcal
                  </span>
                  {item.portion_size != null && item.portion_unit && (
                    <span className="text-xs text-muted">
                      / {item.portion_size} {item.portion_unit}
                    </span>
                  )}
                </div>
              )}

              {item.ingredients.length > 0 && (
                <div>
                  <p className="mb-2 text-xs font-bold text-muted">
                    {lang === 'tr' ? 'İçindekiler' : 'Ingredients'}
                  </p>
                  <p className="text-sm text-textStrong leading-relaxed">
                    {item.ingredients.join(', ')}
                  </p>
                </div>
              )}

              <p className="text-[10px] text-muted">
                {lang === 'tr'
                  ? 'Değerler tahmini olabilir. Alerji durumunuz için personelle iletişime geçin.'
                  : 'Values may be approximate. Please inform staff of your allergies.'}
              </p>
            </div>
          )}

          {item.allergens.length > 0 && (
            <div className="rounded-2xl border border-border bg-bg p-4">
              <p className="mb-3 text-xs font-black uppercase tracking-widest text-muted">
                {lang === 'tr' ? 'Alerjenler' : 'Allergens'}
              </p>
              <div className="flex flex-wrap gap-2">
                {item.allergens.map((code) => {
                  const info = ALLERGEN_LIST.find((a) => a.code === code);
                  return (
                    <span
                      key={code}
                      className="flex items-center gap-1.5 rounded-full border border-border bg-card px-3 py-1 text-xs font-bold text-textStrong"
                    >
                      {/* eslint-disable-next-line @next/next/no-img-element */}
                      <img src={`/allergens/allergen_${code}.svg`} alt="" width={16} height={16} className="shrink-0" />
                      <span>{lang === 'tr' ? info?.labelTr : (info?.labelEn ?? code)}</span>
                    </span>
                  );
                })}
              </div>
              <p className="mt-2 text-[10px] text-muted">
                {lang === 'tr'
                  ? 'Alerji bilgileriniz için lütfen personelle iletişime geçin.'
                  : 'Please inform staff of your allergies before ordering.'}
              </p>
            </div>
          )}
        </div>
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

function PriceSparkline({ entries, lang, showCurrencySymbol }: {
  entries: PriceHistoryEntry[];
  lang: AppLang;
  showCurrencySymbol: boolean;
}) {
  const sorted = [...entries].sort(
    (a, b) => new Date(a.created_at).getTime() - new Date(b.created_at).getTime(),
  );
  const first = sorted[0];
  const prices = [
    ...(first?.old_price_cents != null ? [first.old_price_cents] : []),
    ...sorted.map((entry) => entry.new_price_cents),
  ];
  const min = Math.min(...prices);
  const max = Math.max(...prices);
  const range = max - min || 1;
  const W = 200;
  const H = 40;
  const pts = prices.map((p, i) => ({
    x: (i / Math.max(prices.length - 1, 1)) * W,
    y: H - ((p - min) / range) * H * 0.8 - H * 0.1,
  }));
  const d = pts.map((p, i) => `${i === 0 ? 'M' : 'L'} ${p.x} ${p.y}`).join(' ');
  const latest = sorted[sorted.length - 1];
  const oldestPrice = first.old_price_cents ?? first.new_price_cents;
  const delta = latest.new_price_cents - oldestPrice;
  // Use Tailwind token classes so dark mode CSS variables apply automatically
  const sparklineClass = delta > 0 ? 'text-danger' : delta < 0 ? 'text-success' : 'text-muted';
  const currency = latest.currency || 'TRY';

  return (
    <div className="space-y-2">
      <svg viewBox={`0 0 ${W} ${H}`} className={`w-full ${sparklineClass}`} aria-hidden="true">
        <path d={d} fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" />
        {pts.map((p, i) => (
          <circle key={i} cx={p.x} cy={p.y} r="2.5" fill="currentColor" />
        ))}
      </svg>
      <div className="flex items-center justify-between text-xs text-muted">
        <span>{new Date(first.created_at).toLocaleDateString(lang === 'tr' ? 'tr-TR' : 'en-US', { day: 'numeric', month: 'short' })}</span>
        <span className={`font-extrabold ${delta > 0 ? 'text-danger' : delta < 0 ? 'text-success' : 'text-muted'}`}>
          {delta !== 0 && (delta > 0 ? '+' : '')}
          {formatCurrency(delta, lang, currency, showCurrencySymbol)}
        </span>
        <span>{new Date(latest.created_at).toLocaleDateString(lang === 'tr' ? 'tr-TR' : 'en-US', { day: 'numeric', month: 'short' })}</span>
      </div>
    </div>
  );
}
