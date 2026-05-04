import type { Metadata } from 'next';
import { createSupabaseServerClient } from '@/src/lib/supabaseServer';
import { PanelPageHeader } from '@/src/ui/layout/panel-page-header';
import { PanelContentSurface, PanelSectionCard } from '@/src/ui/layout/panel-section-card';
import { PanelEmptyState } from '@/src/ui/components/panel-empty-state';

export const metadata: Metadata = {
  title: 'Silinmiş Menüler | Admin Panel',
  robots: { index: false, follow: false },
};

type Props = { searchParams: Promise<{ page?: string }> };
const PAGE_SIZE = 40;

export default async function AdminTrashPage({ searchParams }: Props) {
  const { page = '1' } = await searchParams;
  const pageNum = Math.max(1, parseInt(page, 10));
  const offset = (pageNum - 1) * PAGE_SIZE;

  const supabase = await createSupabaseServerClient();

  const { data: rows, count } = await (supabase as any)
    .from('menus')
    .select('id, title, business_id, deleted_at, created_at, businesses(name, city)', { count: 'exact' })
    .not('deleted_at', 'is', null)
    .order('deleted_at', { ascending: false })
    .range(offset, offset + PAGE_SIZE - 1) as { data: any[] | null; count: number | null };

  const list = rows ?? [];
  const totalPages = Math.ceil((count ?? 0) / PAGE_SIZE);

  return (
    <div className="flex flex-col">
      <PanelPageHeader
        eyebrow="Admin"
        title="Silinmiş Menüler"
        description={`${count ?? 0} silinmiş menü`}
      />
      <PanelContentSurface className="pt-6">
        {list.length === 0 ? (
          <PanelEmptyState
            icon={<TrashIcon />}
            title="Silinmiş menü yok"
            description="Soft-delete edilmiş menü bulunamadı."
          />
        ) : (
          <PanelSectionCard noPadding>
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b border-border text-left">
                  <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">Menü</th>
                  <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">İşletme</th>
                  <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">Silinme Tarihi</th>
                  <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">İşlem</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-border">
                {list.map((m: any) => (
                  <tr key={m.id} className="hover:bg-black/[0.02]">
                    <td className="px-5 py-3">
                      <p className="font-[700] text-textStrong">{m.title ?? '—'}</p>
                      <p className="font-mono text-xs text-muted">{String(m.id).slice(0, 8)}…</p>
                    </td>
                    <td className="px-5 py-3">
                      <p className="text-textStrong">{m.businesses?.name ?? '—'}</p>
                      <p className="text-xs text-muted">{m.businesses?.city ?? ''}</p>
                    </td>
                    <td className="px-5 py-3 text-xs text-muted">
                      {m.deleted_at
                        ? new Date(m.deleted_at).toLocaleDateString('tr-TR')
                        : '—'}
                    </td>
                    <td className="px-5 py-3">
                      {/* Restore button — görsel, henüz çalışmıyor */}
                      <button
                        disabled
                        title="Bu özellik yakında aktif edilecek"
                        className="cursor-not-allowed rounded-lg border border-border px-3 py-1 text-xs font-[700] text-muted opacity-50"
                      >
                        Geri Al
                      </button>
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
                    <a href={`?page=${pageNum - 1}`} className="rounded-lg border border-border px-3 py-1 text-xs font-[700] text-textStrong hover:bg-black/[0.02]">
                      ← Önceki
                    </a>
                  )}
                  {pageNum < totalPages && (
                    <a href={`?page=${pageNum + 1}`} className="rounded-lg border border-border px-3 py-1 text-xs font-[700] text-textStrong hover:bg-black/[0.02]">
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

function TrashIcon() {
  return (
    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <polyline points="3 6 5 6 21 6" />
      <path d="M19 6l-1 14a2 2 0 0 1-2 2H8a2 2 0 0 1-2-2L5 6" />
      <path d="M10 11v6" />
      <path d="M14 11v6" />
      <path d="M9 6V4a1 1 0 0 1 1-1h4a1 1 0 0 1 1 1v2" />
    </svg>
  );
}
