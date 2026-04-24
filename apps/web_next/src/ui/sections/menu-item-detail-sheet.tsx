'use client';

import Image from 'next/image';
import { useEffect, useRef, type ReactNode } from 'react';
import type { BrandTheme, BrandThemeDefinition } from '@/src/lib/brand-theme';
import { formatCurrency } from '@/src/lib/format';
import type { AppLang, MenuCopy } from '@/src/lib/i18n';
import { buildMenuImageUrl } from '@/src/lib/media-url';
import { getTranslationValue } from '@/src/lib/menu-text';
import { getPresentationViewModel } from '@/src/lib/presentation-view';
import type { SelectedItemDetails } from '@/src/lib/public-menu-page';
import type { PublicMenuPageData } from '@/src/lib/public-menu-page';

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
            </div>
          </div>
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
