export type AdminSearchType = 'businesses' | 'users' | 'all';

export type AdminSearchResult = {
  category: string;
  item_id: string;
  title: string;
  subtitle: string;
  created_at: string | null;
  meta: Record<string, unknown>;
  score: number;
  href: string;
};

export const ADMIN_SEARCH_TYPE_VALUES: AdminSearchType[] = ['businesses', 'users', 'all'];

export const ADMIN_SEARCH_CATEGORY_LABELS: Record<string, string> = {
  business: 'İşletmeler',
  user: 'Kullanıcılar',
  report: 'Raporlar',
  submission: 'İşletme Talepleri',
  claim: 'Sahiplenme Talepleri',
  menu_item: 'Menü Ürünleri',
};

export const ADMIN_SEARCH_CATEGORY_BADGES: Record<string, string> = {
  business: 'bg-green-50 text-green-700',
  user: 'bg-purple-50 text-purple-700',
  report: 'bg-amber-50 text-amber-700',
  submission: 'bg-blue-50 text-blue-700',
  claim: 'bg-cyan-50 text-cyan-700',
  menu_item: 'bg-zinc-100 text-zinc-600',
};

type SearchOptions = {
  limit?: number;
  type?: AdminSearchType;
};

type SupabaseLike = {
  from: (table: string) => any;
};

type QueryResult = {
  data: any[] | null;
  error?: { message?: string } | null;
};

const DEFAULT_LIMIT = 10;

export function normalizeAdminSearchType(value: string | undefined | null): AdminSearchType {
  return ADMIN_SEARCH_TYPE_VALUES.includes(value as AdminSearchType) ? (value as AdminSearchType) : 'businesses';
}

export async function searchAdminIndex(
  supabase: SupabaseLike,
  rawQuery: string,
  options: SearchOptions = {},
): Promise<AdminSearchResult[]> {
  const query = rawQuery.trim();
  if (query.length < 2) return [];

  const limit = Math.max(1, Math.min(options.limit ?? DEFAULT_LIMIT, 30));
  const type = options.type ?? 'all';
  const tasks: Array<Promise<AdminSearchResult[]>> = [];

  if (type === 'businesses' || type === 'all') {
    tasks.push(searchBusinesses(supabase, query, limit));
  }

  if (type === 'users' || type === 'all') {
    tasks.push(searchUsers(supabase, query, limit));
  }

  if (type === 'all') {
    tasks.push(searchReports(supabase, query, limit));
    tasks.push(searchSubmissions(supabase, query, limit));
    tasks.push(searchClaims(supabase, query, limit));
    tasks.push(searchMenuItems(supabase, query, limit));
  }

  const settled = await Promise.allSettled(tasks);
  return settled
    .flatMap((result) => (result.status === 'fulfilled' ? result.value : []))
    .sort((a, b) => b.score - a.score || new Date(b.created_at ?? 0).getTime() - new Date(a.created_at ?? 0).getTime())
    .slice(0, limit);
}

async function searchBusinesses(supabase: SupabaseLike, query: string, limit: number) {
  const pattern = toIlikePattern(query);
  const result = await safeQuery(
    supabase
      .from('businesses')
      .select('id, name, slug, category, city, district, phone, address, is_active, is_verified, created_at')
      .or(`name.ilike.${pattern},slug.ilike.${pattern},city.ilike.${pattern},district.ilike.${pattern},phone.ilike.${pattern}`)
      .order('name', { ascending: true })
      .limit(limit),
  );

  return (result.data ?? []).map((row) => {
    const title = text(row.name, row.id);
    const subtitle = joinParts([row.category, row.district, row.city, row.phone]);
    return makeResult({
      category: 'business',
      item_id: row.id,
      title,
      subtitle,
      created_at: row.created_at,
      meta: row,
      score: scoreMatch(query, [row.name, row.slug, row.city, row.district, row.phone]),
      href: `/yonetici/isletmeler?q=${encodeURIComponent(title)}`,
    });
  });
}

async function searchUsers(supabase: SupabaseLike, query: string, limit: number) {
  const pattern = toIlikePattern(query);
  const result = await safeQuery(
    supabase
      .from('user_profiles')
      .select('user_id, display_name, is_gourmet, shadow_banned, created_at')
      .or(`display_name.ilike.${pattern}`)
      .order('created_at', { ascending: false })
      .limit(limit),
  );

  return (result.data ?? []).map((row) => {
    const userId = text(row.user_id);
    const roleLabel = row.is_gourmet ? 'Gurme' : 'Kullanıcı';
    const statusLabel = row.shadow_banned ? 'Kısıtlı' : 'Aktif';
    const title = text(row.display_name, userId);
    return makeResult({
      category: 'user',
      item_id: userId,
      title,
      subtitle: joinParts([roleLabel, statusLabel]),
      created_at: row.created_at,
      meta: row,
      score: scoreMatch(query, [row.display_name, userId]),
      href: `/yonetici/kullanicilar/${userId}`,
    });
  });
}

async function searchReports(supabase: SupabaseLike, query: string, limit: number) {
  const pattern = toIlikePattern(query);
  const result = await safeQuery(
    supabase
      .from('reports')
      .select('id, target_type, reason, details, status, business_id, created_at')
      .or(`reason.ilike.${pattern},details.ilike.${pattern},target_type.ilike.${pattern},status.ilike.${pattern}`)
      .order('created_at', { ascending: false })
      .limit(limit),
  );

  return (result.data ?? []).map((row) => {
    const title = text(row.reason, row.target_type, row.id);
    return makeResult({
      category: 'report',
      item_id: row.id,
      title,
      subtitle: joinParts([row.target_type, row.status, row.details]),
      created_at: row.created_at,
      meta: row,
      score: scoreMatch(query, [row.reason, row.details, row.target_type, row.status]),
      href: `/yonetici/raporlar?status=all&q=${encodeURIComponent(title)}`,
    });
  });
}

async function searchSubmissions(supabase: SupabaseLike, query: string, limit: number) {
  const pattern = toIlikePattern(query);
  const result = await safeQuery(
    supabase
      .from('business_submissions')
      .select('id, name, city, district, category, address, phone, status, created_at')
      .or(`name.ilike.${pattern},city.ilike.${pattern},district.ilike.${pattern},address.ilike.${pattern},phone.ilike.${pattern}`)
      .order('created_at', { ascending: false })
      .limit(limit),
  );

  return (result.data ?? []).map((row) => {
    const title = text(row.name, row.id);
    return makeResult({
      category: 'submission',
      item_id: row.id,
      title,
      subtitle: joinParts([row.category, row.district, row.city, row.status]),
      created_at: row.created_at,
      meta: row,
      score: scoreMatch(query, [row.name, row.city, row.district, row.address, row.phone]),
      href: '/yonetici/isletme-basvurulari?status=all',
    });
  });
}

async function searchClaims(supabase: SupabaseLike, query: string, limit: number) {
  const pattern = toIlikePattern(query);
  const result = await safeQuery(
    supabase
      .from('owner_claims')
      .select('id, full_name, phone, status, business_id, created_at')
      .or(`full_name.ilike.${pattern},phone.ilike.${pattern},status.ilike.${pattern}`)
      .order('created_at', { ascending: false })
      .limit(limit),
  );

  return (result.data ?? []).map((row) => {
    const title = text(row.full_name, row.phone, row.id);
    return makeResult({
      category: 'claim',
      item_id: row.id,
      title,
      subtitle: joinParts([row.phone, row.status, row.business_id]),
      created_at: row.created_at,
      meta: row,
      score: scoreMatch(query, [row.full_name, row.phone, row.status]),
      href: '/yonetici/itirazlar/claims',
    });
  });
}

async function searchMenuItems(supabase: SupabaseLike, query: string, limit: number) {
  const pattern = toIlikePattern(query);
  const result = await safeQuery(
    supabase
      .from('menu_items')
      .select('id, name, business_id, created_at')
      .or(`name.ilike.${pattern}`)
      .order('created_at', { ascending: false })
      .limit(limit),
  );

  return (result.data ?? []).map((row) => {
    const title = text(row.name, row.id);
    return makeResult({
      category: 'menu_item',
      item_id: row.id,
      title,
      subtitle: row.business_id ?? '-',
      created_at: row.created_at,
      meta: row,
      score: scoreMatch(query, [row.name]),
      href: `/yonetici/isletmeler?q=${encodeURIComponent(row.business_id ?? title)}`,
    });
  });
}

async function safeQuery(query: PromiseLike<QueryResult>): Promise<QueryResult> {
  const result = await query;
  if (result.error) return { data: [] };
  return result;
}

function makeResult(input: AdminSearchResult): AdminSearchResult {
  return {
    ...input,
    title: input.title || input.item_id,
    subtitle: input.subtitle || '-',
  };
}

function toIlikePattern(value: string) {
  return `*${value.replace(/[,*]/g, ' ').trim().replace(/\s+/g, '%')}*`;
}

function text(...values: unknown[]) {
  for (const value of values) {
    if (typeof value === 'string' && value.trim()) return value.trim();
  }
  return '';
}

function joinParts(values: unknown[]) {
  return values
    .filter((value): value is string => typeof value === 'string' && value.trim().length > 0)
    .map((value) => value.trim())
    .join(' · ');
}

function scoreMatch(query: string, values: unknown[]) {
  const normalizedQuery = normalize(query);
  if (!normalizedQuery) return 0;

  let best = 10;
  for (const value of values) {
    if (typeof value !== 'string') continue;
    const normalizedValue = normalize(value);
    if (!normalizedValue) continue;
    if (normalizedValue === normalizedQuery) best = Math.max(best, 1000);
    else if (normalizedValue.startsWith(normalizedQuery)) best = Math.max(best, 800);
    else if (normalizedValue.includes(normalizedQuery)) best = Math.max(best, 600);
  }
  return best;
}

function normalize(value: string) {
  return value.trim().toLocaleLowerCase('tr-TR');
}
