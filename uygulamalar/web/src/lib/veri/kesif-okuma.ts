import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { logger } from '@/src/lib/kayitci';
import type { Business } from '@/src/lib/veri/isletme-okuma';

export type DiscoverOpts = {
  q?: string;
  city?: string;
  category?: string;
  page?: number;
  pageSize?: number;
};

const businessSelect =
  'id,name,slug,description,logo_url,cover_url,category,city,address,phone,is_verified,is_active';

/**
 * Türkçe karakter normalizer — mobil `sorgu_normalizlayici.dart` ile senkron.
 * "Döner" → "doner", "Şiş" → "sis" vb.
 */
function normalizeQuery(raw: string): string {
  const map: Record<string, string> = {
    ı: 'i', ö: 'o', ü: 'u', ş: 's', ç: 'c', ğ: 'g',
    â: 'a', î: 'i', û: 'u',
    İ: 'i', Ö: 'o', Ü: 'u', Ş: 's', Ç: 'c', Ğ: 'g',
  };
  return raw
    .trim()
    .toLowerCase()
    .replace(/[ıöüşçğâîûİÖÜŞÇĞ]/g, (c) => map[c] ?? c)
    .replace(/[^a-z0-9\s]/g, ' ')
    .replace(/\s+/g, ' ')
    .trim();
}

export async function discoverBusinesses(opts: DiscoverOpts = {}): Promise<{
  data: Business[];
  count: number;
  totalPages: number;
}> {
  const supabase = await createSupabaseServerClient();
  const page = Math.max(1, opts.page ?? 1);
  const pageSize = Math.min(100, Math.max(1, opts.pageSize ?? 20));
  const from = (page - 1) * pageSize;
  const to = from + pageSize - 1;

  // Sorgu varsa: trigram tabanlı RPC (yazım hatası toleranslı, Türkçe normalize)
  // Sorgu yoksa: kategori/şehir filtreli tablo taraması
  if (opts.q?.trim()) {
    const normalized = normalizeQuery(opts.q);

    const { data: rpcData, error: rpcError } = await (supabase as any).rpc(
      'search_businesses_v1',
      {
        p_query: normalized,
        p_city: opts.city?.trim() || null,
        p_district: null,
        p_limit: pageSize,
        p_offset: from,
      },
    );

    if (rpcError) {
      // RPC başarısız olursa ilike fallback
      logger.warn('search_businesses_v1 failed, falling back to ilike', { rpcError });
      return ilikeFallback(supabase, opts, from, to, pageSize);
    }

    const rows = (rpcData ?? []) as Business[];

    // Kategori filtresi RPC'de yoksa client-side uygula
    const filtered = opts.category
      ? rows.filter((b: any) => b.category === opts.category)
      : rows;

    return {
      data: filtered,
      count: filtered.length,
      totalPages: filtered.length < pageSize ? page : page + 1,
    };
  }

  return ilikeFallback(supabase, opts, from, to, pageSize);
}

async function ilikeFallback(
  supabase: any,
  opts: DiscoverOpts,
  from: number,
  to: number,
  pageSize: number,
) {
  let query = supabase
    .from('businesses')
    .select(businessSelect, { count: 'exact' })
    .eq('is_active', true)
    .range(from, to)
    .order('created_at', { ascending: false });

  if (opts.q) {
    // ilike yedek: hem orijinal hem normalleştirilmiş terimi dene
    const normalized = normalizeQuery(opts.q);
    query = query.or(`name.ilike.%${opts.q}%,name.ilike.%${normalized}%`);
  }
  if (opts.city) {
    query = query.eq('city', opts.city);
  }
  if (opts.category) {
    query = query.eq('category', opts.category);
  }

  const { data, error, count } = await query;

  if (error) {
    logger.error('discoverBusinesses failed', { opts, error });
    return { data: [], count: 0, totalPages: 0 };
  }

  const total = count ?? 0;
  const totalPages = pageSize > 0 ? Math.ceil(total / pageSize) : 0;

  return {
    data: ((data ?? []) as Business[]),
    count: total,
    totalPages,
  };
}
