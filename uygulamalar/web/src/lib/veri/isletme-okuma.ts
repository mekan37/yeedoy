import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { logger } from '@/src/lib/kayitci';
import type { Database } from '@/src/lib/taban/veri-tanimlari';

type BusinessRow = Database['public']['Tables']['businesses']['Row'];

export type Business = Pick<
  BusinessRow,
  | 'id'
  | 'name'
  | 'slug'
  | 'description'
  | 'logo_url'
  | 'cover_url'
  | 'category'
  | 'city'
  | 'address'
  | 'phone'
  | 'is_verified'
  | 'is_active'
> & {
  website: string | null;
};

const businessSelect =
  'id,name,slug,description,logo_url,cover_url,category,city,address,phone,is_verified,is_active';

export async function getBusinessBySlug(slug: string): Promise<Business | null> {
  const supabase = await createSupabaseServerClient();
  const { data, error } = await supabase
    .from('businesses')
    .select(businessSelect)
    .or(`slug.eq.${slug},public_slug.eq.${slug}`)
    .maybeSingle();

  if (error) {
    logger.error('getBusinessBySlug failed', { slug, error });
    return null;
  }

  if (!data) return null;
  return { ...(data as BusinessRow), website: null } as Business;
}

export async function getBusinessById(id: string): Promise<Business | null> {
  const supabase = await createSupabaseServerClient();
  const { data, error } = await supabase
    .from('businesses')
    .select(businessSelect)
    .eq('id', id)
    .maybeSingle();

  if (error) {
    logger.error('getBusinessById failed', { id, error });
    return null;
  }

  if (!data) return null;
  return { ...(data as BusinessRow), website: null } as Business;
}

export type ListActiveBusinessesOpts = {
  q?: string;
  city?: string;
  category?: string;
  from?: number;
  to?: number;
};

export async function listActiveBusinesses(
  opts: ListActiveBusinessesOpts = {},
): Promise<{ data: Business[]; count: number }> {
  const supabase = await createSupabaseServerClient();
  const from = opts.from ?? 0;
  const to = opts.to ?? 49;

  let query = supabase
    .from('businesses')
    .select(businessSelect, { count: 'exact' })
    .eq('is_active', true)
    .range(from, to)
    .order('name', { ascending: true });

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
    logger.error('listActiveBusinesses failed', { opts, error });
    return { data: [], count: 0 };
  }

  const rows = ((data ?? []) as BusinessRow[]).map((row) => ({
    ...row,
    website: null,
  })) as Business[];

  return { data: rows, count: count ?? 0 };
}
