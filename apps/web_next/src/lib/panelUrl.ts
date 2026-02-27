const FALLBACK_PANEL_URL = 'http://localhost:8080';

function normalizeBaseUrl(raw: string): string {
  const trimmed = raw.trim();
  if (!trimmed) return FALLBACK_PANEL_URL;
  try {
    return new URL(trimmed).toString();
  } catch {
    return FALLBACK_PANEL_URL;
  }
}

export function panelUrl(pathname: string): string {
  const base = normalizeBaseUrl(process.env.BASE_URL_PANEL ?? FALLBACK_PANEL_URL);
  const normalizedPath = pathname.startsWith('/') ? pathname : `/${pathname}`;
  return new URL(normalizedPath, base).toString();
}
