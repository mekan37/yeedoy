import type { Metadata } from 'next';
import Link from 'next/link';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { createSupabaseServiceClient } from '@/src/lib/taban/hizmet';
import { PanelSayfaBasligi } from '@/src/ui/yerlesim/panel-page-header';
import { PanelIcerikYuzeyi, PanelBolumKarti } from '@/src/ui/yerlesim/panel-section-card';
import { PanelEmptyState } from '@/src/ui/bilesenler/panel-bos-durum';

export const metadata: Metadata = {
  title: 'Yorumlar | Yonetici Paneli',
  robots: { index: false, follow: false },
};

type Props = { searchParams: Promise<{ visible?: string; page?: string; sort?: string; dir?: string } > };
const PAGE_SIZE = 40;
type SortKey = 'review' | 'business' | 'user' | 'rating' | 'status' | 'created_at';
type SortDirection = 'asc' | 'desc';

type ReviewRow = {
  id: string;
  business_id: string;
  user_id: string | null;
  rating: number;
  title: string | null;
  content: string | null;
  status: string;
  created_at: string;
};

type ReviewListRow = ReviewRow & {
  business_name: string | null;
  user_display_name: string | null;
};

export default async function AdminReviewsPage({ searchParams }: Props) {
  const { visible = 'all', page = '1', sort = 'created_at', dir = 'desc' } = await searchParams;
  const sortKey = normalizeSort(sort);
  const sortDirection = normalizeDirection(dir);
  const pageNum = Math.max(1, parseInt(page, 10));
  const offset = (pageNum - 1) * PAGE_SIZE;

  const supabase = await createSupabaseServerClient();
  const searchClient = createSupabaseServiceClient() ?? supabase;
  const { data: reviews, count } = await fetchReviews(searchClient as any, {
    visible,
    sort: sortKey,
    dir: sortDirection,
    offset,
  });
  const list = reviews;
  const totalPages = Math.ceil((count ?? 0) / PAGE_SIZE);
  const queryBase = buildQueryString({ visible, sort: sortKey, dir: sortDirection });

  return (
    <div className="flex flex-col">
      <PanelSayfaBasligi
        eyebrow="Yönetici"
        title="Yorumlar"
        description={count != null ? `${count.toLocaleString('tr-TR')} yorum` : ''}
      />
      <PanelIcerikYuzeyi className="pt-6">
        <form method="get" className="mb-4 flex gap-2">
          <input type="hidden" name="sort" value={sortKey} />
          <input type="hidden" name="dir" value={sortDirection} />
          {[
            { value: 'all', label: 'Tümü' },
            { value: 'visible', label: 'Görünür' },
            { value: 'hidden', label: 'Gizli' },
          ].map(({ value, label }) => (
            <button key={value} type="submit" name="visible" value={value}
              className={`rounded-lg px-3 py-1.5 text-xs font-bold transition-colors ${
                visible === value ? 'bg-primary text-white' : 'border border-border bg-card text-muted hover:text-textStrong'
              }`}>
              {label}
            </button>
          ))}
        </form>

        {list.length === 0 ? (
          <PanelEmptyState icon={<StarIcon />} title="Yorum bulunamadı" />
        ) : (
          <PanelBolumKarti noPadding>
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b border-border text-left">
                  <SortableHeader label="Yorum" column="review" activeSort={sortKey} direction={sortDirection} visible={visible} />
                  <SortableHeader label="İşletme" column="business" activeSort={sortKey} direction={sortDirection} visible={visible} />
                  <SortableHeader label="Kullanıcı" column="user" activeSort={sortKey} direction={sortDirection} visible={visible} />
                  <SortableHeader label="Puan" column="rating" activeSort={sortKey} direction={sortDirection} visible={visible} />
                  <SortableHeader label="Durum" column="status" activeSort={sortKey} direction={sortDirection} visible={visible} />
                  <SortableHeader label="Tarih" column="created_at" activeSort={sortKey} direction={sortDirection} visible={visible} />
                </tr>
              </thead>
              <tbody className="divide-y divide-border">
                {list.map((r: any) => (
                  <tr key={r.id} className="hover:bg-black/1">
                    <td className="max-w-xs px-5 py-3">
                      {r.title && <p className="mb-0.5 text-xs font-extrabold text-textStrong">{r.title}</p>}
                      <p className="line-clamp-2 text-xs text-muted">{r.content ?? '—'}</p>
                    </td>
                    <td className="px-5 py-3 font-bold text-textStrong">{r.business_name ?? '—'}</td>
                    <td className="px-5 py-3 text-muted">{r.user_display_name ?? r.user_id?.slice(0, 12) ?? '—'}</td>
                    <td className="px-5 py-3">
                      <span className="font-extrabold text-amber-500">{'★'.repeat(Math.max(0, Math.min(5, r.rating)))}{'☆'.repeat(5 - Math.max(0, Math.min(5, r.rating)))}</span>
                    </td>
                    <td className="px-5 py-3">
                      <span className={`rounded-full px-2 py-0.5 text-[10px] font-extrabold ${
                        r.status === 'approved' ? 'bg-green-50 text-green-700' : r.status === 'pending' ? 'bg-amber-50 text-amber-700' : 'bg-zinc-100 text-zinc-500'
                      }`}>
                        {reviewStatusLabel(r.status)}
                      </span>
                    </td>
                    <td className="px-5 py-3 text-xs text-muted">
                      {new Date(r.created_at).toLocaleDateString('tr-TR')}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
            {totalPages > 1 && (
              <div className="flex items-center justify-between border-t border-border px-5 py-3">
                <span className="text-xs text-muted">Sayfa {pageNum} / {totalPages}</span>
                <div className="flex gap-2">
                  {pageNum > 1 && <Link href={`?${queryBase}&page=${pageNum - 1}`} className="rounded-lg border border-border px-3 py-1 text-xs font-bold text-textStrong hover:bg-black/2">← Önceki</Link>}
                  {pageNum < totalPages && <Link href={`?${queryBase}&page=${pageNum + 1}`} className="rounded-lg border border-border px-3 py-1 text-xs font-bold text-textStrong hover:bg-black/2">Sonraki →</Link>}
                </div>
              </div>
            )}
          </PanelBolumKarti>
        )}
      </PanelIcerikYuzeyi>
    </div>
  );
}

async function fetchReviews(
  supabase: any,
  input: { visible: string; sort: SortKey; dir: SortDirection; offset: number },
): Promise<{ data: ReviewListRow[]; count: number | null }> {
  let query = supabase
    .from('reviews')
    .select('id, business_id, user_id, rating, title, content, status, created_at', { count: 'exact' });

  if (input.visible === 'visible') query = query.eq('status', 'approved');
  if (input.visible === 'hidden') query = query.neq('status', 'approved');

  if (isDatabaseSort(input.sort)) {
    query = query.order(getDatabaseSortColumn(input.sort), {
      ascending: input.dir === 'asc',
      nullsFirst: false,
    });
  } else {
    query = query.order('created_at', { ascending: false });
  }

  query = query.range(input.offset, input.offset + PAGE_SIZE - 1);

  const { data, count, error } = await query as {
    data: ReviewRow[] | null;
    count: number | null;
    error: { message?: string } | null;
  };

  if (error) return { data: [], count: 0 };

  const rows = data ?? [];
  const [businesses, profiles] = await Promise.all([
    getBusinessNames(supabase, rows.map((row) => row.business_id)),
    getProfileNames(supabase, rows.map((row) => row.user_id).filter((id): id is string => Boolean(id))),
  ]);

  const enriched = rows.map((row) => ({
      ...row,
      business_name: businesses.get(row.business_id) ?? null,
      user_display_name: row.user_id ? profiles.get(row.user_id) ?? null : null,
    }));

  return {
    data: sortEnrichedRows(enriched, input.sort, input.dir),
    count,
  };
}

function SortableHeader({
  label,
  column,
  activeSort,
  direction,
  visible,
}: {
  label: string;
  column: SortKey;
  activeSort: SortKey;
  direction: SortDirection;
  visible: string;
}) {
  const isActive = activeSort === column;
  const nextDirection: SortDirection = isActive && direction === 'asc' ? 'desc' : 'asc';
  const href = `?${buildQueryString({ visible, sort: column, dir: nextDirection })}&page=1`;

  return (
    <th className="px-5 py-3 text-left">
      <Link
        href={href}
        className={`inline-flex min-h-8 items-center gap-1 rounded-md text-[11px] font-extrabold uppercase tracking-wide transition-colors hover:text-textStrong ${
          isActive ? 'text-primary' : 'text-muted'
        }`}
      >
        {label}
        <span aria-hidden="true">{isActive ? (direction === 'asc' ? '▲' : '▼') : '↕'}</span>
      </Link>
    </th>
  );
}

function normalizeSort(value: string): SortKey {
  if (['review', 'business', 'user', 'rating', 'status', 'created_at'].includes(value)) return value as SortKey;
  return 'created_at';
}

function normalizeDirection(value: string): SortDirection {
  return value === 'asc' ? 'asc' : 'desc';
}

function buildQueryString(input: Record<string, string>) {
  const params = new URLSearchParams();
  Object.entries(input).forEach(([key, value]) => {
    if (value) params.set(key, value);
  });
  return params.toString();
}

function isDatabaseSort(sort: SortKey) {
  return sort === 'review' || sort === 'rating' || sort === 'status' || sort === 'created_at';
}

function getDatabaseSortColumn(sort: SortKey) {
  if (sort === 'review') return 'content';
  return sort;
}

function sortEnrichedRows(rows: ReviewListRow[], sort: SortKey, dir: SortDirection) {
  if (sort !== 'business' && sort !== 'user') return rows;
  const multiplier = dir === 'asc' ? 1 : -1;
  return [...rows].sort((a, b) => {
    const left = sort === 'business' ? a.business_name ?? '' : a.user_display_name ?? a.user_id ?? '';
    const right = sort === 'business' ? b.business_name ?? '' : b.user_display_name ?? b.user_id ?? '';
    return left.localeCompare(right, 'tr') * multiplier;
  });
}

async function getBusinessNames(supabase: any, ids: string[]) {
  const uniqueIds = [...new Set(ids)];
  if (uniqueIds.length === 0) return new Map<string, string>();

  const { data } = await supabase
    .from('businesses')
    .select('id, name')
    .in('id', uniqueIds);

  return new Map(((data ?? []) as any[]).map((row) => [row.id, row.name]));
}

async function getProfileNames(supabase: any, userIds: string[]) {
  const uniqueIds = [...new Set(userIds)];
  if (uniqueIds.length === 0) return new Map<string, string>();

  const { data } = await supabase
    .from('user_profiles')
    .select('user_id, display_name')
    .in('user_id', uniqueIds);

  return new Map(((data ?? []) as any[]).map((row) => [row.user_id, row.display_name]));
}

function reviewStatusLabel(status: string) {
  if (status === 'approved') return 'Görünür';
  if (status === 'pending') return 'Bekliyor';
  if (status === 'rejected') return 'Gizli';
  return status;
}

function StarIcon() {
  return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2" /></svg>;
}

