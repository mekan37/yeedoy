import type { Metadata } from 'next';
import Link from 'next/link';
import { createSupabaseServerClient } from '@/src/lib/supabaseServer';
import { PanelPageHeader } from '@/src/ui/layout/panel-page-header';
import { PanelContentSurface, PanelSectionCard } from '@/src/ui/layout/panel-section-card';
import { PanelEmptyState } from '@/src/ui/components/panel-empty-state';
import { PanelActionButton } from '@/src/ui/components/panel-action-button';

export const metadata: Metadata = {
  title: 'İşletmeler | Admin Panel',
  robots: { index: false, follow: false },
};

type Props = { searchParams: Promise<{ q?: string; page?: string }> };

const PAGE_SIZE = 40;

export default async function AdminBusinessesPage({ searchParams }: Props) {
  const { q = '', page = '1' } = await searchParams;
  const pageNum = Math.max(1, parseInt(page, 10));
  const offset = (pageNum - 1) * PAGE_SIZE;

  const supabase = await createSupabaseServerClient();

  type BusinessRow = { id: string; name: string; slug: string | null; category: string; city: string | null; is_active: boolean; is_verified: boolean; created_at: string };

  const baseQuery = (supabase as any)
    .from('businesses')
    .select('id, name, slug, category, city, is_active, is_verified, created_at', { count: 'exact' })
    .order('created_at', { ascending: false })
    .range(offset, offset + PAGE_SIZE - 1);

  const { data: businesses, count } = await (q ? baseQuery.ilike('name', `%${q}%`) : baseQuery) as { data: BusinessRow[] | null; count: number | null };
  const list = businesses ?? [];
  const totalPages = Math.ceil((count ?? 0) / PAGE_SIZE);

  return (
    <div className="flex flex-col">
      <PanelPageHeader
        eyebrow="Admin"
        title="İşletmeler"
        description={count != null ? `${count.toLocaleString('tr-TR')} işletme` : ''}
        actions={
          <Link href="/admin/businesses/new">
            <PanelActionButton variant="primary" icon={<PlusIcon />}>
              Yeni İşletme Ekle
            </PanelActionButton>
          </Link>
        }
      />
      <PanelContentSurface className="pt-6">
        {/* Search */}
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
            icon={<BuildingIcon />}
            title={q ? 'Sonuç bulunamadı' : 'İşletme yok'}
          />
        ) : (
          <PanelSectionCard noPadding>
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b border-border text-left">
                  <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">İsim</th>
                  <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">Kategori</th>
                  <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">Şehir</th>
                  <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">Durum</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-border">
                {list.map((b) => (
                  <tr key={b.id} className="hover:bg-black/[0.02]">
                    <td className="px-5 py-3">
                      <Link
                        href={`/admin/businesses/${b.id}`}
                        className="font-[700] text-textStrong hover:text-[color:var(--yd-color-primary)]"
                      >
                        {b.name}
                      </Link>
                      <p className="text-xs text-muted">{b.slug ?? '—'}</p>
                    </td>
                    <td className="px-5 py-3 text-muted">{b.category}</td>
                    <td className="px-5 py-3 text-muted">{b.city ?? '—'}</td>
                    <td className="px-5 py-3">
                      <div className="flex items-center gap-2">
                        <span
                          className={`rounded-full px-2 py-0.5 text-[11px] font-[800] ${
                            b.is_active ? 'bg-green-50 text-green-700' : 'bg-zinc-100 text-zinc-500'
                          }`}
                        >
                          {b.is_active ? 'Aktif' : 'Pasif'}
                        </span>
                        {b.is_verified && (
                          <span className="rounded-full bg-blue-50 px-2 py-0.5 text-[11px] font-[800] text-blue-700">
                            Onaylı
                          </span>
                        )}
                      </div>
                    </td>
                  </tr>
                ))}
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
                      href={`?q=${q}&page=${pageNum - 1}`}
                      className="rounded-lg border border-border px-3 py-1.5 text-xs font-[700] hover:bg-black/[0.04]"
                    >
                      Önceki
                    </Link>
                  )}
                  {pageNum < totalPages && (
                    <Link
                      href={`?q=${q}&page=${pageNum + 1}`}
                      className="rounded-lg border border-border px-3 py-1.5 text-xs font-[700] hover:bg-black/[0.04]"
                    >
                      Sonraki
                    </Link>
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
