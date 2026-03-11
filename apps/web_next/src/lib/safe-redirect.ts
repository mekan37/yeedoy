export function sanitizeInternalRedirect(input?: string | null, fallback = '/') {
  const value = (input ?? '').trim();
  if (!value) return fallback;

  try {
    const decoded = decodeURIComponent(value);
    const url = new URL(decoded, 'http://local.test');

    if (url.origin !== 'http://local.test') return fallback;
    if (!url.pathname.startsWith('/')) return fallback;
    if (url.pathname.startsWith('//')) return fallback;

    return `${url.pathname}${url.search}${url.hash}`;
  } catch {
    return fallback;
  }
}
