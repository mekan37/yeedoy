import { createSupabaseBrowserClient } from '@/src/lib/taban/istemci';

const CACHE_KEY = 'yeedoy_moderation_blacklist_v1';
const CACHE_TTL_MS = 24 * 60 * 60 * 1000;

export function normalizeForModeration(text: string): string {
  let s = text.toLowerCase();
  s = s
    .replace(/ç/g, 'c').replace(/ğ/g, 'g').replace(/ı/g, 'i')
    .replace(/ö/g, 'o').replace(/ş/g, 's').replace(/ü/g, 'u')
    .replace(/@/g, 'a').replace(/4/g, 'a').replace(/0/g, 'o')
    .replace(/1/g, 'i').replace(/!/g, 'i').replace(/\$/g, 's')
    .replace(/5/g, 's').replace(/3/g, 'e');
  return s.replace(/[^a-z0-9]+/g, ' ').trim();
}

export function matchesBlacklist(text: string, blacklist: string[]): boolean {
  if (blacklist.length === 0) return false;
  const normalizedText = normalizeForModeration(text);
  const compactText = normalizedText.replace(/ /g, '');
  for (const term of blacklist) {
    const normalizedTerm = normalizeForModeration(term);
    if (!normalizedTerm) continue;
    if (normalizedText.includes(normalizedTerm)) return true;
    const compactTerm = normalizedTerm.replace(/ /g, '');
    if (compactTerm && compactText.includes(compactTerm)) return true;
  }
  return false;
}

type CachedList = { terms: string[]; cachedAt: number };

async function fetchBlacklist(): Promise<string[]> {
  const supabase = createSupabaseBrowserClient();
  const sb = supabase as unknown as { rpc: (fn: string) => Promise<{ data: unknown; error: unknown }> };
  const { data, error } = await sb.rpc('get_moderation_blacklist_terms_v1');
  if (error || !Array.isArray(data)) return [];
  return (data as Array<{ term?: string }>).map((row) => row.term ?? '').filter(Boolean);
}

export async function getBlacklistTerms(): Promise<string[]> {
  if (typeof window === 'undefined') return [];
  try {
    const raw = window.localStorage.getItem(CACHE_KEY);
    if (raw) {
      const cached = JSON.parse(raw) as CachedList;
      if (Date.now() - cached.cachedAt < CACHE_TTL_MS && Array.isArray(cached.terms)) {
        return cached.terms;
      }
    }
  } catch {
    // localStorage erişilemez veya bozuk veri — sessizce sunucudan çek
  }

  const terms = await fetchBlacklist();
  try {
    window.localStorage.setItem(CACHE_KEY, JSON.stringify({ terms, cachedAt: Date.now() } satisfies CachedList));
  } catch {
    // localStorage yazılamadı — önbellek olmadan devam, sorun değil
  }
  return terms;
}
