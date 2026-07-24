import { createSupabaseServerClient } from '@/src/lib/supabaseServer';
import { logger } from '@/src/lib/kayitci';
import type { Business } from '@/src/lib/db/business-read';

export type DiscoverOpts = {
  q?: string;
  city?: string;
  category?: string;
  page?: number;
  pageSize?: number;
};

const businessSelect =
  'id,name,slug,description,logo_url,cover_url,category,city,address,phone,is_verified,is_active';

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

  let query = supabase
    .from('businesses')
    .select(businessSelect, { count: 'exact' })
    .eq('is_active', true)
    .range(from, to)
    .order('created_at', { ascending: false });

  if (opts.q) {
    query = query.ilike('name', `%${opts.q}%`);
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

export async function getTopBusinesses(limit = 10): Promise<Business[]> {
  const supabase = await createSupabaseServerClient();
  const supabaseAny = supabase as unknown as { from: (t: string) => any; rpc: (fn: string, args?: any) => any; storage: any; auth: any };

  // Attempt to sort by review_count if the column exists (not in generated types — use any).
  const { data, error } = await supabaseAny
    .from('businesses')
    .select(businessSelect)
    .eq('is_active', true)
    .order('review_count', { ascending: false, nullsFirst: false })
    .limit(limit);

  if (!error && data && (data as unknown[]).length > 0) {
    return data as Business[];
  }

  // Fall back to created_at ordering.
  const { data: fallbackData, error: fallbackError } = await supabase
    .from('businesses')
    .select(businessSelect)
    .eq('is_active', true)
    .order('created_at', { ascending: false })
    .limit(limit);

  if (fallbackError) {
    logger.error('getTopBusinesses failed', { limit, error: fallbackError });
    return [];
  }

  return (fallbackData ?? []) as Business[];
}
