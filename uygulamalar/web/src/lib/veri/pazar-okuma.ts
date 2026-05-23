import { unstable_cache } from 'next/cache';
import { createSupabasePublicClient } from '@/src/lib/taban/acik';
import { logger } from '@/src/lib/kayitci';
import type { AcikIsletmeKarti, AcikYorumKarti } from '@/src/ui/acik/tipler';

export type MarketplaceSearchParams = {
  q?: string;
  city?: string;
  category?: string;
  page?: number;
  pageSize?: number;
};

type MarketplaceBusinessDetail = AcikIsletmeKarti & {
  phone?: string | null;
  website?: string | null;
  lat?: number | null;
  lng?: number | null;
  hours?: Array<{ label: string; value: string; active?: boolean }>;
};

const businessSelect =
  'id,name,slug,public_slug,description,logo_url,cover_url,category,city,district,address,is_verified,is_active,created_at';

const fallbackBusinesses: AcikIsletmeKarti[] = [];

function getFallbackBusinessDetail(slug: string): MarketplaceBusinessDetail | null {
  const business = fallbackBusinesses.find((item) => item.slug === slug || item.id === slug);
  if (!business) return null;
  return {
    ...business,
    phone: null,
    website: null,
    lat: null,
    lng: null,
    hours: [
      { label: 'Pazartesi', value: '09:00 - 22:00' },
      { label: 'Salı', value: '09:00 - 22:00' },
      { label: 'Çarşamba', value: '09:00 - 22:00' },
      { label: 'Perşembe', value: '09:00 - 22:00' },
      { label: 'Cuma', value: '09:00 - 23:00' },
      { label: 'Cumartesi', value: '10:00 - 23:00' },
      { label: 'Pazar', value: '10:00 - 21:00' },
    ],
  };
}

function getFallbackBusinesses(params: MarketplaceSearchParams = {}) {
  const q = params.q?.trim().toLocaleLowerCase('tr-TR') ?? '';
  const city = params.city?.trim().toLocaleLowerCase('tr-TR') ?? '';
  const category = params.category?.trim().toLocaleLowerCase('tr-TR') ?? '';
  const page = Math.max(1, params.page ?? 1);
  const pageSize = Math.min(48, Math.max(1, params.pageSize ?? 18));
  const from = (page - 1) * pageSize;
  const filtered = fallbackBusinesses.filter((business) => {
    const haystack = [business.name, business.category, business.city, business.district, business.description]
      .filter(Boolean)
      .join(' ')
      .toLocaleLowerCase('tr-TR');
    if (q && !haystack.includes(q)) return false;
    if (city && business.city?.toLocaleLowerCase('tr-TR') !== city) return false;
    if (category && business.category?.toLocaleLowerCase('tr-TR') !== category) return false;
    return true;
  });

  return {
    data: filtered.slice(from, from + pageSize),
    count: filtered.length,
    totalPages: Math.ceil(filtered.length / pageSize),
  };
}

function normalizeBusiness(row: any): AcikIsletmeKarti {
  const slug = row.slug ?? row.public_slug ?? row.id;
  return {
    id: row.id,
    name: row.name,
    slug,
    publicSlug: row.public_slug ?? null,
    category: row.category ?? null,
    description: row.description ?? null,
    city: row.city ?? null,
    district: row.district ?? null,
    address: row.address ?? null,
    logoUrl: row.logo_url ?? null,
    coverUrl: row.cover_url ?? null,
    isVerified: row.is_verified ?? false,
    isActive: row.is_active ?? true,
    avgRating: typeof row.avg_rating === 'number' ? row.avg_rating : null,
    reviewCount: typeof row.review_count === 'number' ? row.review_count : null,
    distanceKm: typeof row.distance_km === 'number' ? row.distance_km : null,
    medianPriceCents: typeof row.median_price_cents === 'number' ? row.median_price_cents : null,
    recentPriceVerifiedCount: typeof row.recent_price_verified_count === 'number' ? row.recent_price_verified_count : null,
    isOpenNow: typeof row.is_open_now === 'boolean' ? row.is_open_now : null,
    menuHref: `/m/${slug}`,
  };
}

export async function getMarketplaceBusinesses(params: MarketplaceSearchParams = {}) {
  const supabase = createSupabasePublicClient();
  const page = Math.max(1, params.page ?? 1);
  const pageSize = Math.min(48, Math.max(1, params.pageSize ?? 18));
  const from = (page - 1) * pageSize;
  const to = from + pageSize - 1;
  const q = params.q?.trim();
  const city = params.city?.trim();
  const category = params.category?.trim();

  let query = (supabase as any)
    .from('businesses')
    .select(businessSelect, { count: 'exact' })
    .eq('is_active', true)
    .order('created_at', { ascending: false })
    .range(from, to);

  if (q) query = query.ilike('name', `%${q}%`);
  if (city) query = query.eq('city', city);
  if (category) query = query.eq('category', category);

  const { data, error, count } = await query as { data: any[] | null; error: any; count: number | null };
  if (error) {
    logger.error('getMarketplaceBusinesses failed', { params, error });
    return getFallbackBusinesses(params);
  }

  const rows = (data ?? []).map(normalizeBusiness);
  const enriched = await enrichBusinessCards(rows);
  const total = count ?? 0;
  return {
    data: enriched,
    count: total,
    totalPages: pageSize > 0 ? Math.ceil(total / pageSize) : 0,
  };
}

export const getMarketplaceHome = unstable_cache(
  async () => {
    const [featured, top] = await Promise.all([
      getMarketplaceBusinesses({ pageSize: 9 }),
      getTopMarketplaceBusinesses(6),
    ]);
    return { featured: featured.data, top };
  },
  ['marketplace-home-v2'],
  { revalidate: 120 },
);

export async function getTopMarketplaceBusinesses(limit = 6): Promise<AcikIsletmeKarti[]> {
  const supabase = createSupabasePublicClient();
  try {
    const { data, error } = await (supabase as any).rpc('get_top_businesses_period_v1', {
      p_period: 'week',
      p_limit: limit,
    }) as { data: any[] | null; error: any };
    if (!error && data && data.length > 0) {
      const byId = await getBusinessesByIds(data.map((row) => row.id ?? row.business_id).filter(Boolean));
      return data.map((row) => ({
        ...(byId.get(row.id ?? row.business_id) ?? normalizeBusiness(row)),
        avgRating: Number(row.avg_rating ?? 0) || null,
        reviewCount: Number(row.reviews_count ?? row.review_count ?? 0) || null,
      })).slice(0, limit);
    }
  } catch (error) {
    logger.warn('getTopMarketplaceBusinesses rpc fallback', { error });
  }
  const fallback = await getMarketplaceBusinesses({ pageSize: limit });
  return fallback.data.length > 0 ? fallback.data : getFallbackBusinesses({ pageSize: limit }).data;
}

async function getBusinessesByIds(ids: string[]) {
  const supabase = createSupabasePublicClient();
  if (ids.length === 0) return new Map<string, AcikIsletmeKarti>();
  const { data } = await (supabase as any)
    .from('businesses')
    .select(businessSelect)
    .in('id', ids)
    .eq('is_active', true) as { data: any[] | null };
  return new Map((data ?? []).map((row) => [row.id, normalizeBusiness(row)]));
}

export async function getMarketplaceBusinessBySlug(slug: string) {
  const supabase = createSupabasePublicClient();
  let { data, error } = await (supabase as any)
    .from('businesses')
    .select(`${businessSelect},phone,lat,lng`)
    .or(`slug.eq.${escapePostgrestValue(slug)},public_slug.eq.${escapePostgrestValue(slug)}`)
    .eq('is_active', true)
    .maybeSingle() as { data: any | null; error: any };

  if (!data && !error && isUuid(slug)) {
    const byId = await (supabase as any)
      .from('businesses')
      .select(`${businessSelect},phone,lat,lng`)
      .eq('id', slug)
      .eq('is_active', true)
      .maybeSingle() as { data: any | null; error: any };
    data = byId.data;
    error = byId.error;
  }

  if (error) {
    logger.error('getMarketplaceBusinessBySlug failed', { slug, error: serializeSupabaseError(error) });
    return getFallbackBusinessDetail(slug);
  }
  if (!data) return getFallbackBusinessDetail(slug);
  const [card] = await enrichBusinessCards([normalizeBusiness(data)]);
  const [menu, hours] = await Promise.all([getBusinessMenuHref(data.id, card.slug), getBusinessHoursRows(data.id)]);
  return {
    ...card,
    phone: data.phone ?? null,
    website: null,
    lat: data.lat ?? null,
    lng: data.lng ?? null,
    menuHref: menu,
    hours,
  };
}

function isUuid(value: string) {
  return /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(value);
}

function escapePostgrestValue(value: string) {
  return value.replace(/\\/g, '\\\\').replace(/,/g, '\\,').replace(/\)/g, '\\)');
}

function serializeSupabaseError(error: any) {
  if (!error || typeof error !== 'object') return error;
  return {
    code: error.code,
    message: error.message,
    details: error.details,
    hint: error.hint,
  };
}

export async function getBusinessMenuHref(businessId: string, fallbackSlug: string) {
  const supabase = createSupabasePublicClient();
  const { data } = await (supabase as any)
    .from('menus')
    .select('id,slug')
    .eq('business_id', businessId)
    .eq('status', 'published')
    .order('version', { ascending: false })
    .limit(1)
    .maybeSingle() as { data: { id: string; slug: string | null } | null };
  return `/m/${data?.slug ?? fallbackSlug}`;
}

export async function getBusinessReviews(businessId: string, limit = 5): Promise<AcikYorumKarti[]> {
  const supabase = createSupabasePublicClient();
  try {
    const { data, error } = await (supabase as any).rpc('get_business_reviews_v3', {
      p_business_id: businessId,
      p_sort: 'helpful',
      p_limit: limit,
      p_offset: 0,
    }) as { data: any[] | null; error: any };
    if (!error && data) {
      return data.map(normalizeReview);
    }
  } catch {
    // fall through to table fallback
  }

  const { data } = await (supabase as any)
    .from('business_reviews')
    .select('id,rating,body,content,created_at,verified_visit,user_profiles!user_id(display_name)')
    .eq('business_id', businessId)
    .eq('is_visible', true)
    .order('created_at', { ascending: false })
    .limit(limit) as { data: any[] | null };
  return (data ?? []).map(normalizeReview);
}

function normalizeReview(row: any): AcikYorumKarti {
  return {
    id: row.id,
    author: row.author_name ?? row.user_profiles?.display_name ?? 'Anonim Gurme',
    rating: Number(row.rating ?? row.overall_rating ?? 0),
    content: row.content ?? row.body ?? null,
    createdAt: row.created_at ?? new Date().toISOString(),
    verifiedVisit: row.verified_visit ?? row.is_verified ?? false,
    helpfulCount: row.helpful_count ?? null,
  };
}

async function enrichBusinessCards(businesses: AcikIsletmeKarti[]) {
  if (businesses.length === 0) return businesses;
  const supabase = createSupabasePublicClient();
  const ids = businesses.map((business) => business.id);

  const [ratings, prices] = await Promise.all([
    (supabase as any)
      .from('business_reviews')
      .select('business_id,rating')
      .in('business_id', ids)
      .eq('is_visible', true) as Promise<{ data: Array<{ business_id: string; rating: number }> | null }>,
    (supabase as any)
      .from('regional_price_index')
      .select('business_id,median_price_cents')
      .in('business_id', ids) as Promise<{ data: Array<{ business_id: string; median_price_cents: number }> | null }>,
  ]).catch(() => [{ data: null }, { data: null }] as const);

  const ratingBuckets = new Map<string, number[]>();
  for (const row of ratings.data ?? []) {
    const list = ratingBuckets.get(row.business_id) ?? [];
    list.push(Number(row.rating));
    ratingBuckets.set(row.business_id, list);
  }
  const priceByBusiness = new Map((prices.data ?? []).map((row) => [row.business_id, row.median_price_cents]));

  return businesses.map((business) => {
    const list = ratingBuckets.get(business.id) ?? [];
    return {
      ...business,
      avgRating: business.avgRating ?? (list.length > 0 ? list.reduce((sum, value) => sum + value, 0) / list.length : null),
      reviewCount: business.reviewCount ?? (list.length > 0 ? list.length : null),
      medianPriceCents: business.medianPriceCents ?? priceByBusiness.get(business.id) ?? null,
    };
  });
}

async function getBusinessHoursRows(businessId: string) {
  const supabase = createSupabasePublicClient();
  const { data } = await (supabase as any).from('business_hours').select('*').eq('business_id', businessId).maybeSingle() as { data: any | null };
  if (!data) return [];
  const days = [
    ['Pazartesi', data.mon_open, data.mon_close, 1],
    ['Salı', data.tue_open, data.tue_close, 2],
    ['Çarşamba', data.wed_open, data.wed_close, 3],
    ['Perşembe', data.thu_open, data.thu_close, 4],
    ['Cuma', data.fri_open, data.fri_close, 5],
    ['Cumartesi', data.sat_open, data.sat_close, 6],
    ['Pazar', data.sun_open, data.sun_close, 0],
  ] as const;
  const today = new Date().getDay();
  return days.map(([label, open, close, day]) => ({
    label,
    value: open && close ? `${String(open).slice(0, 5)} - ${String(close).slice(0, 5)}` : 'Kapalı',
    active: day === today,
  }));
}
