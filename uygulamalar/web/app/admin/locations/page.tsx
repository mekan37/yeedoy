import type { Metadata } from 'next';
import { createSupabaseServerClient } from '@/src/lib/supabaseServer';
import { PanelPageHeader } from '@/src/ui/layout/panel-page-header';
import { PanelContentSurface, PanelSectionCard } from '@/src/ui/layout/panel-section-card';
import { PanelEmptyState } from '@/src/ui/components/panel-empty-state';

export const metadata: Metadata = {
  title: 'Konumlar | Admin Panel',
  robots: { index: false, follow: false },
};

type Props = { searchParams: Promise<{ q?: string; view?: string; page?: string }> };
const PAGE_SIZE = 40;

export default async function AdminLocationsPage({ searchParams }: Props) {
  const { q = '', view = 'cities', page = '1' } = await searchParams;
  const pageNum = Math.max(1, parseInt(page, 10));
  const offset = (pageNum - 1) * PAGE_SIZE;

  const supabase = await createSupabaseServerClient();

  const tableName = view === 'districts' ? 'districts' : 'cities';

  let list: any[] = [];
  let count: number | null = 0;
  let totalPages = 0;
  let fetchError = false;

  try {
    const baseQuery = (supabase as any)
      .from(tableName)
      .select('*', { count: 'exact' })
      .order('name', { ascending: true })
      .range(offset, offset + PAGE_SIZE - 1);

    const res = await (q ? baseQuery.ilike('name', `%${q}%`) : baseQuery) as {
      data: any[] | null;
      count: number | null;
      error: any;
    };

    if (res.error) {
      fetchError = true;
    } else {
      list = res.data ?? [];
      count = res.count;
      totalPages = Math.ceil((count ?? 0) / PAGE_SIZE);
    }
  } catch {
    fetchError = true;
  }

  return (
    <div className="flex flex-col">
      <PanelPageHeader
        eyebrow="Admin"
        title="Konumlar"
        description={fetchError ? 'Tablo erişilemiyor' : `${count ?? 0} kayıt`}
      />
      <PanelContentSurface className="pt-6">
        {fetchError ? (
          <PanelEmptyState
            icon={<MapPinIcon />}
            title="Bu özellik yakında aktif edilecek"
            description="cities veya districts tablosu henüz yapılandırılmamış olabilir."
          />
        ) : (
          <div className="flex flex-col gap-4">
            {/* View toggle + search */}
            <div className="flex flex-wrap items-center gap-3">
              <form method="get" className="flex gap-2">
                <input type="hidden" name="q" value={q} />
                {[
                  { value: 'cities', label: 'İller' },
                  { value: 'districts', label: 'İlçeler' },
                ].map(({ value, label }) => (
                  <button
                    key={value}
                    type="submit"
                    name="view"
                    value={value}
                    className={`rounded-lg px-3 py-1.5 text-xs font-[700] transition-colors ${
                      view === value
                        ? 'bg-primary text-white'
                        : 'border border-border bg-card text-muted hover:text-textStrong'
                    }`}
                  >
                    {label}
                  </button>
                ))}
              </form>

              <form method="get" className="flex-1">
                <input type="hidden" name="view" value={view} />
                <input
                  name="q"
                  defaultValue={q}
                  placeholder={view === 'districts' ? 'İlçe ara...' : 'İl ara...'}
                  className="w-full max-w-sm rounded-xl border border-border bg-card px-4 py-2 text-sm text-textStrong placeholder:text-muted focus:outline-none focus:ring-2 focus:ring-primary/30"
                />
              </form>
            </div>

            {list.length === 0 ? (
              <PanelEmptyState
                icon={<MapPinIcon />}
                title={q ? 'Sonuç bulunamadı' : `${view === 'districts' ? 'İlçe' : 'İl'} yok`}
              />
            ) : (
              <PanelSectionCard noPadding>
                <table className="w-full text-sm">
                  <thead>
                    <tr className="border-b border-border text-left">
                      <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">
                        {view === 'districts' ? 'İlçe Adı' : 'İl Adı'}
                      </th>
                      {list[0] && 'code' in list[0] && (
                        <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">Kod</th>
                      )}
                      {list[0] && 'city_id' in list[0] && (
                        <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">İl ID</th>
                      )}
                      {list[0] && 'country' in list[0] && (
                        <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">Ülke</th>
                      )}
                      <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">ID</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-border">
                    {list.map((loc: any) => (
                      <tr key={loc.id} className="hover:bg-black/[0.02]">
                        <td className="px-5 py-3 font-[700] text-textStrong">{loc.name ?? '—'}</td>
                        {loc.code !== undefined && (
                          <td className="px-5 py-3 font-mono text-xs text-muted">{loc.code ?? '—'}</td>
                        )}
                        {loc.city_id !== undefined && (
                          <td className="px-5 py-3 font-mono text-xs text-muted">
                            {loc.city_id ? String(loc.city_id).slice(0, 8) + '…' : '—'}
                          </td>
                        )}
                        {loc.country !== undefined && (
                          <td className="px-5 py-3 text-muted">{loc.country ?? '—'}</td>
                        )}
                        <td className="px-5 py-3 font-mono text-xs text-muted">
                          {String(loc.id).slice(0, 8)}…
                        </td>
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
                          href={`?view=${view}&q=${q}&page=${pageNum - 1}`}
                          className="rounded-lg border border-border px-3 py-1 text-xs font-[700] text-textStrong hover:bg-black/[0.02]"
                        >
                          ← Önceki
                        </a>
                      )}
                      {pageNum < totalPages && (
                        <a
                          href={`?view=${view}&q=${q}&page=${pageNum + 1}`}
                          className="rounded-lg border border-border px-3 py-1 text-xs font-[700] text-textStrong hover:bg-black/[0.02]"
                        >
                          Sonraki →
                        </a>
                      )}
                    </div>
                  </div>
                )}
              </PanelSectionCard>
            )}
          </div>
        )}
      </PanelContentSurface>
    </div>
  );
}

function MapPinIcon() {
  return (
    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0 1 18 0z" />
      <circle cx="12" cy="10" r="3" />
    </svg>
  );
}
