import { cache } from 'react';
import { unstable_cache } from 'next/cache';
import { createSupabasePublicClient } from '@/src/lib/taban/acik';
import { logger } from '@/src/lib/kayitci';
import { escapePostgrestValue } from '@/src/lib/postgrest-yardimcilari';
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
  acceptsReservations: boolean;
  reservationPhone: string | null;
  reservationMinParty: number;
  reservationMaxParty: number;
  reservationNote: string | null;
};

const businessSelect =
  'id,name,slug,public_slug,description,logo_url,cover_url,category,city,district,address,is_verified,is_active,created_at,accepts_reservations,reservation_phone,reservation_min_party,reservation_max_party,reservation_note,price_level';

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
    acceptsReservations: false,
    reservationPhone: null,
    reservationMinParty: 1,
    reservationMaxParty: 20,
    reservationNote: null,
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

type BusinessNormalizeInput = {
  id: string;
  name?: string | null;
  slug?: string | null;
  public_slug?: string | null;
  category?: string | null;
  description?: string | null;
  city?: string | null;
  district?: string | null;
  address?: string | null;
  logo_url?: string | null;
  cover_url?: string | null;
  is_verified?: boolean | null;
  is_active?: boolean | null;
  avg_rating?: number | null;
  review_count?: number | null;
  distance_km?: number | null;
  price_level?: string | null;
  median_price_cents?: number | null;
  recent_price_verified_count?: number | null;
  is_open_now?: boolean | null;
};

function normalizeBusiness(row: BusinessNormalizeInput): AcikIsletmeKarti {
  const slug = row.slug ?? row.public_slug ?? row.id;
  return {
    id: row.id,
    name: row.name ?? '',
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
    priceLevel: typeof row.price_level === 'string' ? row.price_level : null,
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

  let query = supabase
    .from('businesses')
    .select(businessSelect, { count: 'exact' })
    .eq('is_active', true)
    .order('created_at', { ascending: false })
    .range(from, to);

  if (q) query = query.ilike('name', `%${q}%`);
  if (city) query = query.eq('city', city);
  if (category) query = query.eq('category', category);

  const { data, error, count } = await query;
  if (error) {
    logger.warn('getMarketplaceBusinesses fallback', { params });
    return getFallbackBusinesses(params);
  }

  const rows = (data ?? []).map(normalizeBusiness);
  let enriched = rows;
  try {
    enriched = await enrichBusinessCards(rows);
  } catch (enrichErr) {
    logger.warn('enrichBusinessCards failed, returning raw rows', { enrichErr });
  }
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

type TopBusinessRow = {
  id?: string;
  business_id?: string;
  avg_rating?: number | null;
  reviews_count?: number | null;
  review_count?: number | null;
};

export async function getTopMarketplaceBusinesses(limit = 6): Promise<AcikIsletmeKarti[]> {
  const supabase = createSupabasePublicClient();
  try {
    const { data, error } = await supabase.rpc('get_top_businesses_period_v1', {
      p_period: 'week',
      p_limit: limit,
    });
    const rows = ((data ?? []) as unknown as TopBusinessRow[])
      .map((row) => ({ ...row, resolvedId: row.id ?? row.business_id }))
      .filter((row): row is TopBusinessRow & { resolvedId: string } => Boolean(row.resolvedId));
    if (!error && rows.length > 0) {
      const byId = await getBusinessesByIds(rows.map((row) => row.resolvedId));
      return rows.map((row) => ({
        ...(byId.get(row.resolvedId) ?? normalizeBusiness({ id: row.resolvedId, name: row.resolvedId })),
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
  const { data } = await supabase
    .from('businesses')
    .select(businessSelect)
    .in('id', ids)
    .eq('is_active', true);
  return new Map((data ?? []).map((row) => [row.id, normalizeBusiness(row)]));
}

// React cache(): generateMetadata + sayfa bileşeni aynı request içinde bu
// fonksiyonu 2 kez çağırıyordu (~4 sorgudan oluşan zincir, toplam ~8
// round-trip) — [sehir]/[slug]'da zaten kullanılan pattern burada da uygulandı.
export const getMarketplaceBusinessBySlug = cache(async (slug: string) => {
  const supabase = createSupabasePublicClient();
  let { data, error } = await supabase
    .from('businesses')
    .select(`${businessSelect},phone,lat,lng`)
    .or(`slug.eq.${escapePostgrestValue(slug)},public_slug.eq.${escapePostgrestValue(slug)}`)
    .eq('is_active', true)
    .maybeSingle();

  if (!data && !error && isUuid(slug)) {
    const byId = await supabase
      .from('businesses')
      .select(`${businessSelect},phone,lat,lng`)
      .eq('id', slug)
      .eq('is_active', true)
      .maybeSingle();
    data = byId.data;
    error = byId.error;
  }

  if (error) {
    logger.warn('getMarketplaceBusinessBySlug fallback', { slug });
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
    acceptsReservations: data.accepts_reservations === true,
    reservationPhone: typeof data.reservation_phone === 'string' ? data.reservation_phone : null,
    reservationMinParty: typeof data.reservation_min_party === 'number' && data.reservation_min_party > 0 ? data.reservation_min_party : 1,
    reservationMaxParty: typeof data.reservation_max_party === 'number' && data.reservation_max_party > 0 ? data.reservation_max_party : 20,
    reservationNote: typeof data.reservation_note === 'string' ? data.reservation_note : null,
  };
});

function isUuid(value: string) {
  return /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(value);
}

// `menus` hiçbir zaman kendi `slug` kolonuna sahip olmadı — /m/[slug] rotası
// işletmenin slug'ıyla adreslenir, menünün değil. Bu fonksiyon önceden
// `menus.slug` seçen bir sorgu çalıştırıp (her zaman "column does not exist"
// ile hata veren, sessizce yutulan bir sorgu) hep fallbackSlug'a düşüyordu —
// gevşek `any` tabanlı kod bunu gizliyordu, gerçek Supabase tipleriyle ortaya
// çıktı. Sorgunun kendisi hiçbir zaman anlamlı bir sonuç üretmediği için
// kaldırıldı.
export async function getBusinessMenuHref(_businessId: string, fallbackSlug: string) {
  return `/m/${fallbackSlug}`;
}

type ReviewRow = {
  id: string;
  user_id?: string | null;
  rating?: number | null;
  overall_rating?: number | null;
  content?: string | null;
  body?: string | null;
  created_at?: string | null;
  verified_visit?: boolean | null;
  is_verified?: boolean | null;
  helpful_count?: number | null;
  author_name?: string | null;
  user_profiles?: { display_name: string | null } | null;
};

export async function getBusinessReviews(businessId: string, limit = 5): Promise<AcikYorumKarti[]> {
  const supabase = createSupabasePublicClient();
  let rows: ReviewRow[] | null = null;
  try {
    const { data, error } = await supabase.rpc('get_business_reviews_v3', {
      p_business_id: businessId,
      p_sort: 'helpful',
      p_limit: limit,
      p_offset: 0,
    });
    if (!error && data) rows = data as unknown as ReviewRow[];
  } catch {
    // fall through
  }

  if (!rows) {
    const { data } = await supabase
      .from('reviews')
      .select('id,rating,content,created_at,helpful_count,user_profiles!user_id(display_name)')
      .eq('business_id', businessId)
      .eq('status', 'approved')
      .order('created_at', { ascending: false })
      .limit(limit);
    rows = ((data ?? []) as unknown as Array<ReviewRow & { user_profiles: { display_name: string | null }[] | { display_name: string | null } | null }>).map((row) => ({
      ...row,
      user_profiles: Array.isArray(row.user_profiles) ? (row.user_profiles[0] ?? null) : row.user_profiles,
    }));
  }

  // Enrich with author names from user_profiles (RPC doesn't join)
  const userIds = [...new Set(rows.filter((r) => r.user_id).map((r) => r.user_id as string))];
  const nameMap = new Map<string, string>();
  if (userIds.length > 0) {
    try {
      const { data: profiles } = await supabase
        .from('user_profiles')
        .select('user_id,display_name')
        .in('user_id', userIds);
      for (const p of profiles ?? []) {
        if (p.display_name) nameMap.set(p.user_id, p.display_name);
      }
    } catch {
      // author adı olmadan devam
    }
  }

  return rows.map((row) => normalizeReview(row, nameMap));
}

function normalizeReview(row: ReviewRow, nameMap?: Map<string, string>): AcikYorumKarti {
  const author =
    (row.user_id && nameMap?.get(row.user_id)) ??
    row.author_name ??
    row.user_profiles?.display_name ??
    'Anonim Gurme';
  return {
    id: row.id,
    author,
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

  let reviewData: Array<{ business_id: string; rating: number }> | null = null;
  try {
    const result = await supabase
      .from('reviews')
      .select('business_id,rating')
      .in('business_id', ids)
      .eq('status', 'approved');
    reviewData = result.data;
  } catch {
    // enrichment hatası — raw rows döndür
  }

  const ratingBuckets = new Map<string, number[]>();
  for (const row of reviewData ?? []) {
    const list = ratingBuckets.get(row.business_id) ?? [];
    list.push(Number(row.rating));
    ratingBuckets.set(row.business_id, list);
  }

  return businesses.map((business) => {
    const list = ratingBuckets.get(business.id) ?? [];
    return {
      ...business,
      avgRating: business.avgRating ?? (list.length > 0 ? list.reduce((sum, value) => sum + value, 0) / list.length : null),
      reviewCount: business.reviewCount ?? (list.length > 0 ? list.length : null),
    };
  });
}

// day_of_week to display label mapping (0=Pazar, 1=Pazartesi ... 6=Cumartesi)
const DOW_LABELS: Record<number, string> = {
  1: 'Pazartesi',
  2: 'Salı',
  3: 'Çarşamba',
  4: 'Perşembe',
  5: 'Cuma',
  6: 'Cumartesi',
  0: 'Pazar',
};

// Display order for the hours list (Mon→Sun)
const DOW_ORDER = [1, 2, 3, 4, 5, 6, 0];

type BusinessHoursRpcResult = {
  weekly: Array<{ day_of_week: number; open_time: string; close_time: string; is_closed: boolean }>;
  special: unknown[];
  is_open_now: boolean | null;
};

async function getBusinessHoursRows(businessId: string) {
  const supabase = createSupabasePublicClient();

  // Use get_business_hours_v1 which reads business_weekly_hours (canonical table).
  // is_open_now is computed server-side with Europe/Istanbul timezone — no client Date math.
  const { data: rawData } = await supabase.rpc('get_business_hours_v1', {
    p_business_id: businessId,
  });
  const data = rawData as unknown as BusinessHoursRpcResult | null;

  if (!data?.weekly || data.weekly.length === 0) return [];

  const byDow = new Map(data.weekly.map((r) => [r.day_of_week, r]));

  // Istanbul DOW for "today" badge — derived from is_open_now context is not available here,
  // so we use a lightweight server-side approximation: UTC+3 offset.
  const nowIstanbul = new Date(Date.now() + 3 * 60 * 60 * 1000);
  const todayDow = nowIstanbul.getUTCDay(); // 0=Sun ... 6=Sat, same convention as business_weekly_hours

  return DOW_ORDER.map((dow) => {
    const row = byDow.get(dow);
    const label = DOW_LABELS[dow] ?? String(dow);
    if (!row || row.is_closed) {
      return { label, value: 'Kapalı', active: dow === todayDow };
    }
    return {
      label,
      value: `${row.open_time.slice(0, 5)} - ${row.close_time.slice(0, 5)}`,
      active: dow === todayDow,
    };
  });
}
