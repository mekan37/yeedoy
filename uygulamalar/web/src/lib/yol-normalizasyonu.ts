import { resolveBrandTheme } from '@/src/lib/marka-temasi';
import { isUuid } from '@/src/lib/isletme-yolu';
import { resolveLang } from '@/src/lib/ceviri';
export { isUuid } from '@/src/lib/isletme-yolu';

export function normalizeDisplayParams(input: {
  lang?: string | null;
  theme?: string | null;
  src?: string | null;
  preview?: string | null;
}, defaults?: {
  lang?: string | null;
  theme?: string | null;
}) {
  const normalizedLang = input.lang == null ? resolveLang(defaults?.lang) : resolveLang(input.lang);
  const normalizedTheme =
    input.theme == null ? resolveBrandTheme(defaults?.theme) : resolveBrandTheme(input.theme);
  const normalizedSrc = normalizeOptionalParam(input.src);
  const normalizedPreview = input.preview?.trim() === '1';
  const rawLang = normalizeOptionalParam(input.lang)?.toLowerCase() ?? null;
  const rawTheme = normalizeOptionalParam(input.theme)?.toLowerCase() ?? null;
  const rawPreview = normalizeOptionalParam(input.preview);

  return {
    lang: normalizedLang,
    theme: normalizedTheme,
    src: normalizedSrc,
    preview: normalizedPreview,
    hasInvalidParams:
      (rawLang !== null && rawLang !== normalizedLang) ||
      (rawTheme !== null && rawTheme !== normalizedTheme) ||
      (rawPreview !== null && rawPreview !== '1'),
  };
}

function normalizeOptionalParam(value?: string | null) {
  const trimmed = value?.trim();
  return trimmed ? trimmed : null;
}
