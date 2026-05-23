import type { Metadata } from 'next';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { createSupabaseServiceClient } from '@/src/lib/taban/hizmet';
import { PanelSayfaBasligi } from '@/src/ui/yerlesim/panel-page-header';
import { PanelIcerikYuzeyi, PanelBolumKarti } from '@/src/ui/yerlesim/panel-section-card';
import { PanelEmptyState } from '@/src/ui/bilesenler/panel-bos-durum';

export const metadata: Metadata = {
  title: 'Masa Geri Bildirimleri | Yonetici Paneli',
  robots: { index: false, follow: false },
};

type Props = {
  searchParams: Promise<{ q?: string; category?: string; page?: string; sort?: string; dir?: string }>;
};

const PAGE_SIZE = 40;
const SOURCE_LIMIT = 500;
const SORT_KEYS = ['created_at', 'business_name', 'category', 'message', 'rating', 'source'] as const;

type SortKey = (typeof SORT_KEYS)[number];
type SortDir = 'asc' | 'desc';

type FeedbackRow = {
  id: string;
  source: 'menu_feedback' | 'reports';
  business_id: string | null;
  business_name: string | null;
  category: string | null;
  message: string | null;
  rating: number | null;
  created_at: string;
};

const CATEGORY_LABELS: Record<string, string> = {
  menu: 'Menü',
  price: 'Fiyat',
  service: 'Servis',
  app: 'Uygulama',
  other: 'Diğer',
  report: 'Rapor',
};

export default async function AdminTableFeedbackPage({ searchParams }: Props) {
  const { q = '', category = 'all', page = '1', sort = 'created_at', dir = 'desc' } = await searchParams;
  const pageNum = Math.max(1, parseInt(page, 10));
  const offset = (pageNum - 1) * PAGE_SIZE;
  const sortKey = parseSortKey(sort);
  const sortDir: SortDir = dir === 'asc' ? 'asc' : 'desc';

  const supabase = createSupabaseServiceClient() ?? (await createSupabaseServerClient());
  const { list, count, usingFallback } = await listFeedbackRows(supabase as any, {
    q: q.trim(),
    category,
    offset,
    sortKey,
    sortDir,
  });
  const totalPages = Math.ceil(count / PAGE_SIZE);
  const createSortHref = (nextSort: SortKey) => {
    const nextDir: SortDir = sortKey === nextSort && sortDir === 'asc' ? 'desc' : 'asc';
    return `?q=${encodeURIComponent(q)}&category=${encodeURIComponent(category)}&sort=${nextSort}&dir=${nextDir}&page=1`;
  };
  const pageHref = (nextPage: number) =>
    `?q=${encodeURIComponent(q)}&category=${encodeURIComponent(category)}&sort=${sortKey}&dir=${sortDir}&page=${nextPage}`;

  return (
    <div className="flex flex-col">
      <PanelSayfaBasligi
        eyebrow="Admin"
        title="Masa Geri Bildirimleri"
        description={`${count.toLocaleString('tr-TR')} geri bildirim${usingFallback ? ' · raporlardan gösteriliyor' : ''}`}
      />
      <PanelIcerikYuzeyi className="pt-6">
        <div className="flex flex-col gap-4">
          <form method="get" className="flex flex-wrap items-center gap-3 rounded-xl border border-border bg-card p-3">
            <input type="hidden" name="page" value="1" />
            <input type="hidden" name="sort" value={sortKey} />
            <input type="hidden" name="dir" value={sortDir} />
            <input
              name="q"
              defaultValue={q}
              placeholder="İşletme, kategori veya mesaj ara..."
              className="min-h-11 min-w-[240px] flex-1 rounded-xl border border-border bg-bg px-4 py-2 text-sm text-textStrong placeholder:text-muted focus:outline-none focus:ring-2 focus:ring-primary/30"
            />
            <select
              name="category"
              defaultValue={category}
              className="min-h-11 rounded-xl border border-border bg-bg px-3 py-2 text-sm font-[700] text-textStrong focus:outline-none focus:ring-2 focus:ring-primary/30"
            >
              <option value="all">Tüm Kategoriler</option>
              <option value="menu">Menü</option>
              <option value="price">Fiyat</option>
              <option value="service">Servis</option>
              <option value="app">Uygulama</option>
              <option value="other">Diğer</option>
              <option value="report">Rapor</option>
            </select>
            <button
              type="submit"
              className="min-h-11 rounded-xl bg-primary px-4 text-sm font-[800] text-white transition-opacity hover:opacity-90"
            >
              Uygula
            </button>
          </form>

          {list.length === 0 ? (
            <PanelBolumKarti>
              <PanelEmptyState
                icon={<MessageIcon />}
                title={q ? 'Sonuç bulunamadı' : 'Geri bildirim bulunamadı'}
                description="QR menü üzerinden gönderilen geri bildirimler burada görünür."
              />
            </PanelBolumKarti>
          ) : (
            <PanelBolumKarti noPadding>
              <table className="w-full text-sm">
                <thead>
                  <tr className="border-b border-border text-left">
                    <SortableHeader label="Tarih" sortKey="created_at" currentSort={sortKey} currentDir={sortDir} href={createSortHref('created_at')} />
                    <SortableHeader label="İşletme" sortKey="business_name" currentSort={sortKey} currentDir={sortDir} href={createSortHref('business_name')} />
                    <SortableHeader label="Kategori" sortKey="category" currentSort={sortKey} currentDir={sortDir} href={createSortHref('category')} />
                    <SortableHeader label="Mesaj" sortKey="message" currentSort={sortKey} currentDir={sortDir} href={createSortHref('message')} />
                    <SortableHeader label="Puan" sortKey="rating" currentSort={sortKey} currentDir={sortDir} href={createSortHref('rating')} />
                    <SortableHeader label="Kaynak" sortKey="source" currentSort={sortKey} currentDir={sortDir} href={createSortHref('source')} />
                  </tr>
                </thead>
                <tbody className="divide-y divide-border">
                  {list.map((entry) => (
                    <tr key={entry.id} className="hover:bg-black/[0.01]">
                      <td className="whitespace-nowrap px-5 py-3 text-xs text-muted">
                        {new Date(entry.created_at).toLocaleString('tr-TR', {
                          day: '2-digit',
                          month: '2-digit',
                          year: 'numeric',
                          hour: '2-digit',
                          minute: '2-digit',
                        })}
                      </td>
                      <td className="px-5 py-3">
                        <p className="font-[700] text-textStrong">{entry.business_name ?? '—'}</p>
                        <p className="font-mono text-[10px] text-muted">{entry.business_id ? shortId(entry.business_id) : 'işletme yok'}</p>
                      </td>
                      <td className="px-5 py-3">
                        <span className="rounded-full bg-zinc-100 px-2 py-0.5 text-[10px] font-[800] text-zinc-600">
                          {entry.category ? CATEGORY_LABELS[entry.category] ?? entry.category : '—'}
                        </span>
                      </td>
                      <td className="max-w-[340px] px-5 py-3 text-xs text-textStrong">
                        {entry.message ? (
                          <p className="line-clamp-2">{entry.message}</p>
                        ) : (
                          <span className="italic text-muted">Mesaj yok</span>
                        )}
                      </td>
                      <td className={`whitespace-nowrap px-5 py-3 text-xs font-[700] ${ratingColor(entry.rating)}`}>
                        {starLabel(entry.rating)}
                      </td>
                      <td className="px-5 py-3 font-mono text-xs text-muted">{entry.source}</td>
                    </tr>
                  ))}
                </tbody>
              </table>

              {totalPages > 1 && (
                <div className="flex items-center justify-between border-t border-border px-5 py-3">
                  <span className="text-xs text-muted">Sayfa {pageNum} / {totalPages}</span>
                  <div className="flex gap-2">
                    {pageNum > 1 && (
                      <a
                        href={pageHref(pageNum - 1)}
                        className="rounded-lg border border-border px-3 py-1 text-xs font-[700] text-textStrong hover:bg-black/[0.02]"
                      >
                        ← Önceki
                      </a>
                    )}
                    {pageNum < totalPages && (
                      <a
                        href={pageHref(pageNum + 1)}
                        className="rounded-lg border border-border px-3 py-1 text-xs font-[700] text-textStrong hover:bg-black/[0.02]"
                      >
                        Sonraki →
                      </a>
                    )}
                  </div>
                </div>
              )}
            </PanelBolumKarti>
          )}
        </div>
      </PanelIcerikYuzeyi>
    </div>
  );
}

async function listFeedbackRows(
  supabase: any,
  {
    q,
    category,
    offset,
    sortKey,
    sortDir,
  }: { q: string; category: string; offset: number; sortKey: SortKey; sortDir: SortDir },
) {
  const feedbackRes = await safeQuery(
    supabase
      .from('menu_feedback')
      .select('id, business_id, rating, category, message, created_at')
      .order('created_at', { ascending: false })
      .limit(SOURCE_LIMIT),
  );

  const usingFallback = !feedbackRes.ok;
  const sourceRows = feedbackRes.ok
    ? feedbackRes.data.map(mapMenuFeedback)
    : (await safeQuery(
        supabase
          .from('reports')
          .select('id, business_id, reason, details, target_type, status, created_at')
          .in('status', ['open', 'reviewing', 'resolved'])
          .order('created_at', { ascending: false })
          .limit(SOURCE_LIMIT),
      )).data.map(mapReportFeedback);

  const businessNames = await loadBusinessNames(supabase, sourceRows.map((row) => row.business_id).filter(Boolean) as string[]);
  const query = normalizeSearch(q);
  const rows = sourceRows
    .map((row) => ({ ...row, business_name: row.business_id ? businessNames.get(row.business_id) ?? null : null }))
    .filter((row) => category === 'all' || row.category === category)
    .filter((row) => {
      if (!query) return true;
      return normalizeSearch([row.business_name, row.category, row.message, row.business_id].filter(Boolean).join(' ')).includes(query);
    })
    .sort((a, b) => compareFeedbackRows(a, b, sortKey, sortDir));

  return {
    list: rows.slice(offset, offset + PAGE_SIZE),
    count: rows.length,
    usingFallback,
  };
}

async function safeQuery(query: PromiseLike<{ data: any[] | null; error: any }>) {
  try {
    const { data, error } = await query;
    return error ? { ok: false as const, data: [] } : { ok: true as const, data: data ?? [] };
  } catch {
    return { ok: false as const, data: [] };
  }
}

function mapMenuFeedback(row: any): FeedbackRow {
  return {
    id: `menu_feedback:${row.id}`,
    source: 'menu_feedback',
    business_id: row.business_id ?? null,
    business_name: null,
    category: row.category ?? null,
    message: row.message ?? null,
    rating: typeof row.rating === 'number' ? row.rating : null,
    created_at: row.created_at ?? new Date(0).toISOString(),
  };
}

function mapReportFeedback(row: any): FeedbackRow {
  return {
    id: `report:${row.id}`,
    source: 'reports',
    business_id: row.business_id ?? null,
    business_name: null,
    category: 'report',
    message: [row.reason, row.details, row.status ? `durum: ${row.status}` : null].filter(Boolean).join(' · ') || null,
    rating: null,
    created_at: row.created_at ?? new Date(0).toISOString(),
  };
}

async function loadBusinessNames(supabase: any, ids: string[]) {
  const uniqueIds = Array.from(new Set(ids));
  if (uniqueIds.length === 0) return new Map<string, string>();

  const { data, error } = await supabase
    .from('businesses')
    .select('id, name')
    .in('id', uniqueIds);

  if (error) return new Map<string, string>();
  return new Map(((data ?? []) as Array<{ id: string; name: string }>).map((row) => [row.id, row.name]));
}

function SortableHeader({
  label,
  sortKey,
  currentSort,
  currentDir,
  href,
}: {
  label: string;
  sortKey: SortKey;
  currentSort: SortKey;
  currentDir: SortDir;
  href: string;
}) {
  const active = currentSort === sortKey;
  const marker = active ? (currentDir === 'asc' ? '↑' : '↓') : '↕';

  return (
    <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">
      <a href={href} className="inline-flex items-center gap-1.5 hover:text-textStrong">
        <span>{label}</span>
        <span aria-hidden="true" className={active ? 'text-primary' : 'text-muted'}>
          {marker}
        </span>
      </a>
    </th>
  );
}

function parseSortKey(value: string): SortKey {
  return SORT_KEYS.includes(value as SortKey) ? (value as SortKey) : 'created_at';
}

function compareFeedbackRows(a: FeedbackRow, b: FeedbackRow, sortKey: SortKey, sortDir: SortDir) {
  const direction = sortDir === 'asc' ? 1 : -1;
  let result = 0;

  if (sortKey === 'created_at') {
    result = new Date(a.created_at).getTime() - new Date(b.created_at).getTime();
  } else if (sortKey === 'rating') {
    result = (a.rating ?? 0) - (b.rating ?? 0);
  } else {
    result = String(a[sortKey] ?? '').localeCompare(String(b[sortKey] ?? ''), 'tr');
  }

  if (result === 0) {
    result = new Date(b.created_at).getTime() - new Date(a.created_at).getTime();
  }

  return result * direction;
}

function starLabel(rating: number | null): string {
  if (!rating) return '—';
  const clamped = Math.max(0, Math.min(5, rating));
  return '★'.repeat(clamped) + '☆'.repeat(5 - clamped);
}

function ratingColor(rating: number | null): string {
  if (!rating) return 'text-muted';
  if (rating >= 4) return 'text-emerald-600';
  if (rating >= 3) return 'text-amber-600';
  return 'text-red-600';
}

function normalizeSearch(value: string) {
  return value.trim().toLocaleLowerCase('tr-TR');
}

function shortId(value: string) {
  return value.length > 14 ? `${value.slice(0, 10)}…` : value;
}

function MessageIcon() {
  return (
    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z" />
    </svg>
  );
}
