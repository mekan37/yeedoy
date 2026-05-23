import type { Metadata } from 'next';
import { createSupabaseServerClient } from '@/src/lib/supabaseServer';
import { PanelPageHeader } from '@/src/ui/layout/panel-page-header';
import { PanelContentSurface, PanelSectionCard } from '@/src/ui/layout/panel-section-card';
import { PanelEmptyState } from '@/src/ui/components/panel-empty-state';

export const metadata: Metadata = {
  title: 'Doğrulanmış İşletmeler | Admin Panel',
  robots: { index: false, follow: false },
};

type Props = { searchParams: Promise<{ q?: string; page?: string }> };
const PAGE_SIZE = 40;

export default async function AdminVerifiedPage({ searchParams }: Props) {
  const { q = '', page = '1' } = await searchParams;
  const pageNum = Math.max(1, parseInt(page, 10));
  const offset = (pageNum - 1) * PAGE_SIZE;

  const supabase = await createSupabaseServerClient();

  const baseQuery = (supabase as any)
    .from('businesses')
    .select('id, name, slug, category, city, verified_at, created_at', { count: 'exact' })
    .eq('is_verified', true)
    .order('verified_at', { ascending: false })
    .range(offset, offset + PAGE_SIZE - 1);

  const { data: rows, count } = await (
    q ? baseQuery.ilike('name', `%${q}%`) : baseQuery
  ) as { data: any[] | null; count: number | null };

  const list = rows ?? [];
  const totalPages = Math.ceil((count ?? 0) / PAGE_SIZE);

  return (
    <div className="flex flex-col">
      <PanelPageHeader
        eyebrow="Admin"
        title="Doğrulanmış İşletmeler"
        description={count != null ? `${count.toLocaleString('tr-TR')} doğrulanmış işletme` : ''}
      />
      <PanelContentSurface className="pt-6">
        <form method="get" className="mb-4">
          <input
            name="q"
            defaultValue={q}
            placeholder="İşletme ara..."
            className="w-full max-w-sm rounded-xl border border-border bg-card px-4 py-2 text-sm text-textStrong placeholder:text-muted focus:outline-none focus:ring-2 focus:ring-primary/30"
          />
        </form>

        {list.length === 0 ? (
          <PanelEmptyState
            icon={<BadgeCheckIcon />}
            title={q ? 'Sonuç bulunamadı' : 'Doğrulanmış işletme yok'}
          />
        ) : (
          <PanelSectionCard noPadding>
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b border-border text-left">
                  <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">İsim</th>
                  <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">Şehir</th>
                  <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">Kategori</th>
                  <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">Doğrulama Tarihi</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-border">
                {list.map((b: any) => (
                  <tr key={b.id} className="hover:bg-black/[0.02]">
                    <td className="px-5 py-3">
                      <p className="font-[700] text-textStrong">{b.name}</p>
                      <p className="text-xs text-muted">{b.slug ?? '—'}</p>
                    </td>
                    <td className="px-5 py-3 text-muted">{b.city ?? '—'}</td>
                    <td className="px-5 py-3 text-muted">{b.category ?? '—'}</td>
                    <td className="px-5 py-3 text-xs text-muted">
                      {b.verified_at
                        ? new Date(b.verified_at).toLocaleDateString('tr-TR')
                        : '—'}
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
                    <a href={`?q=${q}&page=${pageNum - 1}`} className="rounded-lg border border-border px-3 py-1 text-xs font-[700] text-textStrong hover:bg-black/[0.02]">
                      ← Önceki
                    </a>
                  )}
                  {pageNum < totalPages && (
                    <a href={`?q=${q}&page=${pageNum + 1}`} className="rounded-lg border border-border px-3 py-1 text-xs font-[700] text-textStrong hover:bg-black/[0.02]">
                      Sonraki →
                    </a>
                  )}
                </div>
              </div>
            )}
          </PanelSectionCard>
        )}
      </PanelContentSurface>
    </div>
  );
}

function BadgeCheckIcon() {
  return (
    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z" />
      <polyline points="9 12 11 14 15 10" />
    </svg>
  );
}
