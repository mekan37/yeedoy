import type { BrandTheme } from '@/src/lib/brand-theme';
import { normalizeBusinessMenuPathKey } from '@/src/lib/business-path';
export { normalizeBusinessMenuPathKey } from '@/src/lib/business-path';

type SharedParams = {
  lang?: string | null;
  theme?: BrandTheme | null;
  src?: string | null;
  preview?: boolean | null;
};

export type MenuBusinessPathInput = {
  businessId: string;
  businessSlug?: string | null;
  businessPublicSlug?: string | null;
  businessPathKey?: string | null;
};

export type MenuBusinessPathRecord = {
  id: string;
  slug?: string | null;
  public_slug?: string | null;
};

export function toSearchParams(input: SharedParams) {
  const params = new URLSearchParams();

  if (input.lang) params.set('lang', input.lang);
  if (input.theme) params.set('theme', input.theme);
  if (input.src) params.set('src', input.src);
  if (input.preview) params.set('preview', '1');

  const query = params.toString();
  return query ? `?${query}` : '';
}

export function resolveBusinessMenuPathKey(input: MenuBusinessPathInput) {
  return (
    normalizeBusinessMenuPathKey(input.businessPathKey) ??
    normalizeBusinessMenuPathKey(input.businessPublicSlug) ??
    normalizeBusinessMenuPathKey(input.businessSlug) ??
    normalizeBusinessMenuPathKey(input.businessId) ??
    input.businessId.trim()
  );
}

export function resolveBusinessMenuPathKeyFromRecord(business: MenuBusinessPathRecord) {
  return resolveBusinessMenuPathKey({
    businessId: business.id,
    businessPublicSlug: business.public_slug,
    businessSlug: business.slug,
  });
}

export function buildMenuHref(input: MenuBusinessPathInput & {
  categoryId?: string | null;
  itemId?: string | null;
  lang?: string | null;
  theme?: BrandTheme | null;
  src?: string | null;
  preview?: boolean | null;
}) {
  const businessPathKey = resolveBusinessMenuPathKey(input);
  const base = input.itemId
    ? `/m/${businessPathKey}/i/${input.itemId}`
    : input.categoryId
      ? `/m/${businessPathKey}/c/${input.categoryId}`
      : `/m/${businessPathKey}`;

  return `${base}${toSearchParams({
    lang: input.lang,
    theme: input.theme,
    src: input.src,
    preview: input.preview,
  })}`;
}

export function buildBusinessMenuHref(input: {
  business: MenuBusinessPathRecord;
  categoryId?: string | null;
  itemId?: string | null;
  lang?: string | null;
  theme?: BrandTheme | null;
  src?: string | null;
  preview?: boolean | null;
}) {
  return buildMenuHref({
    businessId: input.business.id,
    businessPublicSlug: input.business.public_slug,
    businessSlug: input.business.slug,
    categoryId: input.categoryId,
    itemId: input.itemId,
    lang: input.lang,
    theme: input.theme,
    src: input.src,
    preview: input.preview,
  });
}

export function buildQrHref(input: {
  businessId: string;
  lang?: string | null;
  theme?: BrandTheme | null;
}) {
  return `/qr/${input.businessId}${toSearchParams({
    lang: input.lang,
    theme: input.theme,
  })}`;
}

export function buildShortHref(input: {
  code: string;
  lang?: string | null;
  theme?: BrandTheme | null;
}) {
  return `/q/${input.code}${toSearchParams({
    lang: input.lang,
    theme: input.theme,
  })}`;
}
