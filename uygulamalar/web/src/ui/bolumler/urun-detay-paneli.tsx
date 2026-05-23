'use client';

import Image from 'next/image';
import { useEffect, useRef, useState, type ReactNode } from 'react';
import type { BrandTheme, BrandThemeDefinition } from '@/src/lib/marka-temasi';
import { formatCurrency } from '@/src/lib/bicimlendirme';
import type { AppLang, MenuCopy } from '@/src/lib/ceviri';
import { buildMenuImageUrl } from '@/src/lib/medya-adresi';
import { getTranslationValue } from '@/src/lib/menu-metinleri';
import { getPresentationViewModel } from '@/src/lib/sunum-gorunumu';
import type { SelectedItemDetails } from '@/src/lib/acik-menu-sayfasi';
import type { PublicMenuPageData } from '@/src/lib/acik-menu-sayfasi';
import type { PriceHistoryEntry } from '@/src/lib/veri/menu-okuma';

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
        <div className="sticky top-0 z-10 flex items-center justify-between border-b border-border bg-card/95 px-5 py-4 backdrop-blur">
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
                <div className="relative aspect-[16/10] overflow-hidden rounded-[28px] bg-cardAlt">
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
                <div className="mt-3">
                  {(selectedItemDetails?.photos.length ?? 0) === 0 ? (
                    <p className="text-sm text-muted">{labels.noResultsBody}</p>
                  ) : (
                    <PhotoCarousel
                      photos={selectedItemDetails!.photos}
                      alt={title}
                      blurDataUrl={blurDataUrl}
                    />
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
        </div>
      </div>
    </div>
  );
}

// Photo carousel with swipe support and dot indicators
function PhotoCarousel({ photos, alt, blurDataUrl }: {
  photos: Array<{ id: string; url: string; url_thumb?: string | null; url_large?: string | null }>;
  alt: string;
  blurDataUrl: string;
}) {
  const [idx, setIdx] = useState(0);
  const [lightbox, setLightbox] = useState(false);
  const startX = useRef<number | null>(null);

  const prev = () => setIdx(i => (i - 1 + photos.length) % photos.length);
  const next = () => setIdx(i => (i + 1) % photos.length);

  const onTouchStart = (e: React.TouchEvent) => { startX.current = e.touches[0]?.clientX ?? null; };
  const onTouchEnd = (e: React.TouchEvent) => {
    if (startX.current === null) return;
    const dx = (e.changedTouches[0]?.clientX ?? 0) - startX.current;
    if (dx < -40) next();
    else if (dx > 40) prev();
    startX.current = null;
  };

  const current = photos[idx];
  if (!current) return null;

  return (
    <>
      {/* Main carousel */}
      <div
        className="group relative overflow-hidden rounded-2xl bg-card"
        onTouchStart={onTouchStart}
        onTouchEnd={onTouchEnd}
      >
        <div className="relative aspect-[4/3] w-full cursor-pointer" onClick={() => setLightbox(true)}>
          <Image
            src={current.url_large ?? current.url}
            alt={`${alt} ${idx + 1}`}
            fill
            unoptimized
            placeholder="blur"
            blurDataURL={blurDataUrl}
            className="object-cover transition-opacity duration-300"
          />
          {/* Zoom hint */}
          <div className="absolute bottom-2 right-2 rounded-lg bg-black/40 px-2 py-1 text-[10px] font-[700] text-white backdrop-blur opacity-0 group-hover:opacity-100 transition-opacity">
            Büyüt
          </div>
        </div>

        {/* Nav arrows */}
        {photos.length > 1 && (
          <>
            <button
              onClick={(e) => { e.stopPropagation(); prev(); }}
              className="absolute left-2 top-1/2 -translate-y-1/2 rounded-full bg-black/40 p-1.5 text-white backdrop-blur hover:bg-black/60 transition-colors"
              aria-label="Önceki fotoğraf"
            >
              <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5"><polyline points="15 18 9 12 15 6" /></svg>
            </button>
            <button
              onClick={(e) => { e.stopPropagation(); next(); }}
              className="absolute right-2 top-1/2 -translate-y-1/2 rounded-full bg-black/40 p-1.5 text-white backdrop-blur hover:bg-black/60 transition-colors"
              aria-label="Sonraki fotoğraf"
            >
              <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5"><polyline points="9 18 15 12 9 6" /></svg>
            </button>
          </>
        )}
      </div>

      {/* Dots + thumbnails */}
      {photos.length > 1 && (
        <div className="mt-2 flex items-center gap-1.5 overflow-x-auto pb-1">
          {photos.map((p, i) => (
            <button
              key={p.id}
              onClick={() => setIdx(i)}
              className={`relative h-14 w-14 shrink-0 overflow-hidden rounded-xl border-2 transition-all ${i === idx ? 'border-primary shadow-sm' : 'border-transparent opacity-60 hover:opacity-90'}`}
              aria-label={`Fotoğraf ${i + 1}`}
            >
              <Image src={p.url_thumb ?? p.url} alt="" fill unoptimized className="object-cover" />
            </button>
          ))}
        </div>
      )}

      {/* Lightbox */}
      {lightbox && (
        <div
          className="fixed inset-0 z-[200] flex items-center justify-center bg-black/90"
          onClick={() => setLightbox(false)}
        >
          <button
            className="absolute right-4 top-4 rounded-full bg-white/10 p-2 text-white hover:bg-white/20"
            onClick={() => setLightbox(false)}
            aria-label="Kapat"
          >
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5"><line x1="18" y1="6" x2="6" y2="18" /><line x1="6" y1="6" x2="18" y2="18" /></svg>
          </button>
          <div className="relative h-[80vh] w-[90vw] max-w-4xl" onClick={e => e.stopPropagation()}>
            <Image
              src={current.url_large ?? current.url}
              alt={alt}
              fill
              unoptimized
              className="object-contain"
            />
          </div>
          {photos.length > 1 && (
            <>
              <button onClick={(e) => { e.stopPropagation(); prev(); }} className="absolute left-4 rounded-full bg-white/10 p-3 text-white hover:bg-white/20">
                <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5"><polyline points="15 18 9 12 15 6" /></svg>
              </button>
              <button onClick={(e) => { e.stopPropagation(); next(); }} className="absolute right-4 rounded-full bg-white/10 p-3 text-white hover:bg-white/20">
                <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5"><polyline points="9 18 15 12 9 6" /></svg>
              </button>
              <p className="absolute bottom-4 left-1/2 -translate-x-1/2 rounded-full bg-black/40 px-3 py-1 text-sm font-[700] text-white">
                {idx + 1} / {photos.length}
              </p>
            </>
          )}
        </div>
      )}
    </>
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
        <span className={`font-[800] ${delta > 0 ? 'text-danger' : delta < 0 ? 'text-success' : 'text-muted'}`}>
          {delta !== 0 && (delta > 0 ? '+' : '')}
          {formatCurrency(delta, lang, currency, showCurrencySymbol)}
        </span>
        <span>{new Date(latest.created_at).toLocaleDateString(lang === 'tr' ? 'tr-TR' : 'en-US', { day: 'numeric', month: 'short' })}</span>
      </div>
    </div>
  );
}
