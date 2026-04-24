export function appendMediaVersion(url: string | null | undefined, version: string | null | undefined) {
  const normalizedUrl = url?.trim();
  const normalizedVersion = version?.trim();

  if (!normalizedUrl || !normalizedVersion) {
    return normalizedUrl ?? null;
  }

  try {
    const resolved = new URL(normalizedUrl);
    resolved.searchParams.set('v', normalizedVersion);
    return resolved.toString();
  } catch {
    return normalizedUrl;
  }
}

// Supabase Storage image transform parameters.
// Docs: https://supabase.com/docs/guides/storage/serving/image-transformations
export type MenuImageOptions = {
  width?: number;
  quality?: number;
};

const SUPABASE_STORAGE_MARKER = '/storage/v1/object/';

/**
 * Appends Supabase Storage transform params (?width=N&quality=Q) to a
 * Supabase-hosted image URL. Non-Supabase URLs and empty strings are returned
 * unchanged so the helper is safe to call on any URL.
 *
 * Usage:
 *   buildMenuImageUrl(item.image_url, { width: 400, quality: 80 })
 *   buildMenuImageUrl(heroUrl, { width: 1200, quality: 85 })
 */
export function buildMenuImageUrl(
  url: string | null | undefined,
  { width = 800, quality = 80 }: MenuImageOptions = {},
): string | null {
  const raw = url?.trim();
  if (!raw) return null;

  if (!raw.includes(SUPABASE_STORAGE_MARKER)) return raw;

  try {
    const resolved = new URL(raw);
    // Supabase Storage transform uses /render/image/ path prefix in the URL.
    // For existing /object/public/ URLs we rewrite to /render/image/public/.
    if (resolved.pathname.includes('/object/public/')) {
      resolved.pathname = resolved.pathname.replace('/object/public/', '/render/image/public/');
    }
    if (width > 0) resolved.searchParams.set('width', String(width));
    if (quality > 0) resolved.searchParams.set('quality', String(quality));
    return resolved.toString();
  } catch {
    return raw;
  }
}
