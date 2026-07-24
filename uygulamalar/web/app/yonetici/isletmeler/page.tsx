import type { Metadata } from 'next';
import Link from 'next/link';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { createSupabaseServiceClient } from '@/src/lib/taban/hizmet';
import { PanelSayfaBasligi } from '@/src/ui/yerlesim/panel-page-header';
import { PanelIcerikYuzeyi, PanelBolumKarti } from '@/src/ui/yerlesim/panel-section-card';
import { PanelEmptyState } from '@/src/ui/bilesenler/panel-bos-durum';
import { PanelActionButton } from '@/src/ui/bilesenler/panel-eylem-dugmesi';

export const metadata: Metadata = {
  title: 'İşletmeler | Yonetici Paneli',
  robots: { index: false, follow: false },
};

type Props = {
  searchParams: Promise<{
    q?: string;
    city?: string;
    district?: string;
    category?: string;
    status?: string;
    sort?: string;
    page?: string;
  }>;
};

const PAGE_SIZE = 40;

type SortKey = 'newest' | 'name' | 'rating' | 'reviews';
type StatusKey = '' | 'active' | 'inactive' | 'verified';

type BusinessRow = {
  id: string;
  name: string;
  slug: string | null;
  public_slug: string | null;
  category: string;
  city: string | null;
  district: string | null;
  is_active: boolean;
  is_verified: boolean;
  created_at: string;
  avg_rating?: number | null;
  average_rating?: number | null;
  review_count?: number | null;
};

const SORT_OPTIONS: Array<{ value: SortKey; label: string }> = [
  { value: 'newest', label: 'En Yeni' },
  { value: 'name', label: 'Ada Göre' },
  { value: 'rating', label: 'En Çok Puan' },
  { value: 'reviews', label: 'En Çok Yorum' },
];

const STATUS_OPTIONS: Array<{ value: StatusKey; label: string }> = [
  { value: '', label: 'Tüm Durumlar' },
  { value: 'active', label: 'Aktif' },
  { value: 'inactive', label: 'Pasif' },
  { value: 'verified', label: 'Onaylı' },
];

export default async function AdminBusinessesPage({ searchParams }: Props) {
  const {
    q = '',
    city = '',
    district = '',
    category = '',
    status = '',
    sort = 'newest',
    page = '1',
  } = await searchParams;
  const sortKey = normalizeSort(sort);
  const statusKey = normalizeStatus(status);
  const pageNum = Math.max(1, parseInt(page, 10));
  const offset = (pageNum - 1) * PAGE_SIZE;

  const supabase = await createSupabaseServerClient();
  const searchClient = createSupabaseServiceClient() ?? supabase;

  const { data: businesses, count } = await fetchBusinesses(searchClient as any, {
    q: q.trim(),
    city: city.trim(),
    district: district.trim(),
    category: category.trim(),
    status: statusKey,
    sort: sortKey,
    offset,
  });

  const list = businesses;
  const totalPages = Math.ceil((count ?? 0) / PAGE_SIZE);
  const queryBase = buildQueryString({ q, city, district, category, status: statusKey, sort: sortKey });
  const verifiedHref = `/yonetici/isletmeler?${buildQueryString({ q, city, district, category, status: 'verified', sort: sortKey })}`;
  const allBusinessesHref = `/yonetici/isletmeler?${buildQueryString({ q, city, district, category, sort: sortKey })}`;

  return (
    <div className="flex flex-col">
      <PanelSayfaBasligi
        eyebrow="Yönetici"
        title="İşletmeler"
        description={count != null ? `${count.toLocaleString('tr-TR')} işletme` : ''}
        actions={
          <Link href="/yonetici/isletmeler/yeni">
            <PanelActionButton variant="primary" icon={<PlusIcon />}>
              Yeni İşletme Ekle
            </PanelActionButton>
          </Link>
        }
      />
      <PanelIcerikYuzeyi className="pt-6">
        <div className="mb-4 flex flex-wrap gap-2">
          <Link
            href={allBusinessesHref}
            className={`inline-flex min-h-10 items-center rounded-xl border px-3 text-xs font-extrabold transition-colors ${
              statusKey === ''
                ? 'border-primary bg-primary text-white'
                : 'border-border bg-card text-muted hover:text-textStrong'
            }`}
          >
            Tüm İşletmeler
          </Link>
          <Link
            href={verifiedHref}
            className={`inline-flex min-h-10 items-center rounded-xl border px-3 text-xs font-extrabold transition-colors ${
              statusKey === 'verified'
                ? 'border-primary bg-primary text-white'
                : 'border-border bg-card text-muted hover:text-textStrong'
            }`}
          >
            Doğrulanmışlar
          </Link>
        </div>
        <form method="get" className="mb-4 grid gap-3 rounded-xl border border-border bg-card p-3 md:grid-cols-[minmax(220px,1.4fr)_repeat(4,minmax(130px,1fr))_auto]">
          <input name="page" value="1" type="hidden" />
          <input
            name="q"
            defaultValue={q}
            placeholder="İşletme, slug, adres ara..."
            className="min-h-11 rounded-xl border border-border bg-bg px-4 py-2 text-sm text-textStrong placeholder:text-muted focus:outline-hidden focus:ring-2 focus:ring-primary/30"
          />
          <input
            name="city"
            defaultValue={city}
            placeholder="Şehir"
            className="min-h-11 rounded-xl border border-border bg-bg px-3 py-2 text-sm text-textStrong placeholder:text-muted focus:outline-hidden focus:ring-2 focus:ring-primary/30"
          />
          <input
            name="district"
            defaultValue={district}
            placeholder="İlçe"
            className="min-h-11 rounded-xl border border-border bg-bg px-3 py-2 text-sm text-textStrong placeholder:text-muted focus:outline-hidden focus:ring-2 focus:ring-primary/30"
          />
          <input
            name="category"
            defaultValue={category}
            placeholder="Kategori"
            className="min-h-11 rounded-xl border border-border bg-bg px-3 py-2 text-sm text-textStrong placeholder:text-muted focus:outline-hidden focus:ring-2 focus:ring-primary/30"
          />
          <select
            name="status"
            defaultValue={statusKey}
            className="min-h-11 rounded-xl border border-border bg-bg px-3 py-2 text-sm font-bold text-textStrong focus:outline-hidden focus:ring-2 focus:ring-primary/30"
          >
            {STATUS_OPTIONS.map((option) => (
              <option key={option.value} value={option.value}>{option.label}</option>
            ))}
          </select>
          <div className="flex gap-2">
            <select
              name="sort"
              defaultValue={sortKey}
              className="min-h-11 rounded-xl border border-border bg-bg px-3 py-2 text-sm font-bold text-textStrong focus:outline-hidden focus:ring-2 focus:ring-primary/30"
            >
              {SORT_OPTIONS.map((option) => (
                <option key={option.value} value={option.value}>{option.label}</option>
              ))}
            </select>
            <button
              type="submit"
              className="min-h-11 rounded-xl bg-primary px-4 text-sm font-extrabold text-white transition-opacity hover:opacity-90"
            >
              Uygula
            </button>
          </div>
        </form>

        {list.length === 0 ? (
          <PanelEmptyState
            icon={<BuildingIcon />}
            title={q ? 'Sonuç bulunamadı' : 'İşletme yok'}
          />
        ) : (
          <PanelBolumKarti noPadding>
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b border-border text-left">
                  <th className="px-5 py-3 text-[11px] font-extrabold uppercase tracking-wide text-muted">İsim</th>
                  <th className="px-5 py-3 text-[11px] font-extrabold uppercase tracking-wide text-muted">Kategori</th>
                  <th className="px-5 py-3 text-[11px] font-extrabold uppercase tracking-wide text-muted">Konum</th>
                  <th className="px-5 py-3 text-[11px] font-extrabold uppercase tracking-wide text-muted">Puan</th>
                  <th className="px-5 py-3 text-[11px] font-extrabold uppercase tracking-wide text-muted">Durum</th>
                  <th className="px-5 py-3 text-right text-[11px] font-extrabold uppercase tracking-wide text-muted">Aksiyon</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-border">
                {list.map((b) => {
                  const publicHref = getPublicBusinessHref(b);
                  const rating = getRating(b);
                  return (
                    <tr key={b.id} className="hover:bg-black/2">
                      <td className="px-5 py-3">
                        <p className="font-bold text-textStrong">{b.name}</p>
                        <p className="text-xs text-muted">{b.slug ?? b.public_slug ?? b.id}</p>
                      </td>
                      <td className="px-5 py-3 text-muted">{b.category}</td>
                      <td className="px-5 py-3 text-muted">{[b.district, b.city].filter(Boolean).join(' / ') || '—'}</td>
                      <td className="px-5 py-3">
                        <div className="flex flex-col gap-0.5">
                          <span className="text-xs font-black text-textStrong">{rating != null ? `★ ${rating.toFixed(1)}` : '—'}</span>
                          <span className="text-[11px] text-muted">{b.review_count != null ? `${b.review_count} yorum` : 'yorum yok'}</span>
                        </div>
                      </td>
                      <td className="px-5 py-3">
                        <div className="flex items-center gap-2">
                          <span
                            className={`rounded-full px-2 py-0.5 text-[11px] font-extrabold ${
                              b.is_active ? 'bg-green-50 text-green-700' : 'bg-zinc-100 text-zinc-500'
                            }`}
                          >
                            {b.is_active ? 'Aktif' : 'Pasif'}
                          </span>
                          {b.is_verified && (
                            <span className="rounded-full bg-blue-50 px-2 py-0.5 text-[11px] font-extrabold text-blue-700">
                              Onaylı
                            </span>
                          )}
                        </div>
                      </td>
                      <td className="px-5 py-3 text-right">
                        {publicHref ? (
                          <Link
                            href={publicHref}
                            className="inline-flex min-h-9 items-center rounded-lg border border-border px-3 text-xs font-extrabold text-textStrong transition-colors hover:border-primary/30 hover:text-primary"
                          >
                            Public Aç
                          </Link>
                        ) : (
                          <span className="text-xs text-muted">Link yok</span>
                        )}
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>

            {/* Pagination */}
            {totalPages > 1 && (
              <div className="flex items-center justify-between border-t border-border px-5 py-3">
                <p className="text-xs text-muted">
                  Sayfa {pageNum} / {totalPages}
                </p>
                <div className="flex gap-2">
                  {pageNum > 1 && (
                    <Link
                      href={`?${queryBase}&page=${pageNum - 1}`}
                      className="rounded-lg border border-border px-3 py-1.5 text-xs font-bold hover:bg-black/4"
                    >
                      Önceki
                    </Link>
                  )}
                  {pageNum < totalPages && (
                    <Link
                      href={`?${queryBase}&page=${pageNum + 1}`}
                      className="rounded-lg border border-border px-3 py-1.5 text-xs font-bold hover:bg-black/4"
                    >
                      Sonraki
                    </Link>
                  )}
                </div>
              </div>
            )}
          </PanelBolumKarti>
        )}
      </PanelIcerikYuzeyi>
    </div>
  );
}

async function fetchBusinesses(
  supabase: any,
  input: {
    q: string;
    city: string;
    district: string;
    category: string;
    status: StatusKey;
    sort: SortKey;
    offset: number;
  },
): Promise<{ data: BusinessRow[]; count: number | null }> {
  const preferred = await runBusinessQuery(
    supabase,
    'id, name, slug, public_slug, category, city, district, is_active, is_verified, created_at, avg_rating, average_rating, review_count',
    input,
  );
  if (!preferred.error) return { data: preferred.data ?? [], count: preferred.count ?? null };

  const fallback = await runBusinessQuery(
    supabase,
    'id, name, slug, public_slug, category, city, district, is_active, is_verified, created_at',
    input,
  );
  return { data: fallback.data ?? [], count: fallback.count ?? null };
}

async function runBusinessQuery(
  supabase: any,
  select: string,
  input: {
    q: string;
    city: string;
    district: string;
    category: string;
    status: StatusKey;
    sort: SortKey;
    offset: number;
  },
): Promise<{ data: BusinessRow[] | null; count: number | null; error: unknown }> {
  let query = supabase
    .from('businesses')
    .select(select, { count: 'exact' });

  if (input.q) {
    const pattern = `%${input.q.replace(/[%,_]/g, ' ').trim()}%`;
    query = query.or(
      `name.ilike.${pattern},slug.ilike.${pattern},public_slug.ilike.${pattern},city.ilike.${pattern},district.ilike.${pattern},category.ilike.${pattern},address.ilike.${pattern}`,
    );
  }
  if (input.city) query = query.ilike('city', `%${input.city}%`);
  if (input.district) query = query.ilike('district', `%${input.district}%`);
  if (input.category) query = query.ilike('category', `%${input.category}%`);
  if (input.status === 'active') query = query.eq('is_active', true);
  if (input.status === 'inactive') query = query.eq('is_active', false);
  if (input.status === 'verified') query = query.eq('is_verified', true);

  if (input.sort === 'name') {
    query = query.order('name', { ascending: true });
  } else if (input.sort === 'rating') {
    query = query.order(select.includes('avg_rating') ? 'avg_rating' : 'created_at', { ascending: false, nullsFirst: false });
  } else if (input.sort === 'reviews') {
    query = query.order(select.includes('review_count') ? 'review_count' : 'created_at', { ascending: false, nullsFirst: false });
  } else {
    query = query.order('created_at', { ascending: false });
  }

  return await query.range(input.offset, input.offset + PAGE_SIZE - 1);
}

function normalizeSort(value: string): SortKey {
  return SORT_OPTIONS.some((option) => option.value === value) ? (value as SortKey) : 'newest';
}

function normalizeStatus(value: string): StatusKey {
  return STATUS_OPTIONS.some((option) => option.value === value) ? (value as StatusKey) : '';
}

function buildQueryString(input: Record<string, string>) {
  const params = new URLSearchParams();
  Object.entries(input).forEach(([key, value]) => {
    if (value) params.set(key, value);
  });
  return params.toString();
}

function getRating(business: BusinessRow) {
  if (typeof business.avg_rating === 'number') return business.avg_rating;
  if (typeof business.average_rating === 'number') return business.average_rating;
  return null;
}

function getPublicBusinessHref(business: BusinessRow) {
  const slug = business.public_slug ?? business.slug;
  return slug ? `/isletme/${encodeURIComponent(slug)}` : null;
}

function BuildingIcon() {
  return (
    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <rect x="4" y="2" width="16" height="20" rx="2" ry="2" /><path d="M9 22V12h6v10" />
    </svg>
  );
}

function PlusIcon() {
  return (
    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
      <line x1="12" y1="5" x2="12" y2="19" /><line x1="5" y1="12" x2="19" y2="12" />
    </svg>
  );
}

