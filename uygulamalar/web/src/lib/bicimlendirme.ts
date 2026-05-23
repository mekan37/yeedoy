const LOCALE_BY_LANG = {
  tr: 'tr-TR',
  en: 'en-US',
} as const;

export function getLocale(lang?: string | null) {
  const normalized = String(lang ?? 'tr').toLowerCase();
  if (normalized.startsWith('en')) return LOCALE_BY_LANG.en;
  return LOCALE_BY_LANG.tr;
}

export function formatCurrency(
  cents: number | null | undefined,
  lang?: string | null,
  currency = 'TRY',
  showSymbol = true,
) {
  if (cents == null) {
    return lang?.startsWith('tr') ? 'Fiyata sorunuz' : 'Price on request';
  }
  if (!showSymbol) {
    return `${(cents / 100).toFixed(2)} ${currency}`;
  }
  try {
    return new Intl.NumberFormat(getLocale(lang), {
      style: 'currency',
      currency,
      maximumFractionDigits: 2,
    }).format(cents / 100);
  } catch {
    return `${(cents / 100).toFixed(2)} ${currency}`;
  }
}

export function formatBusinessLocation(
  business: { neighborhood?: string | null; district?: string | null; city?: string | null },
) {
  return [business.neighborhood, business.district, business.city]
    .map((value) => value?.trim())
    .filter(Boolean)
    .join(' • ');
}

export function formatDateLabel(value: string | null | undefined, lang?: string | null) {
  if (!value) return null;
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return null;
  return new Intl.DateTimeFormat(getLocale(lang), {
    dateStyle: 'medium',
    timeStyle: 'short',
  }).format(date);
}

export function sanitizeText(value: string | null | undefined) {
  return String(value ?? '').trim();
}
