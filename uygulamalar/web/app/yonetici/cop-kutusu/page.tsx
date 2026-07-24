import type { Metadata } from 'next';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { PanelSayfaBasligi } from '@/src/ui/yerlesim/panel-page-header';
import { PanelIcerikYuzeyi, PanelBolumKarti } from '@/src/ui/yerlesim/panel-section-card';
import { PanelEmptyState } from '@/src/ui/bilesenler/panel-bos-durum';
import { AdminMenuGeriAlDugmesi } from './admin-geri-al-dugmesi';

export const metadata: Metadata = {
  title: 'Silinmiş Menüler | Yonetici Paneli',
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
      <PanelSayfaBasligi
        eyebrow="Yönetici"
        title="Silinmiş Menüler"
        description={`${count ?? 0} silinmiş menü`}
      />
      <PanelIcerikYuzeyi className="pt-6">
        {list.length === 0 ? (
          <PanelEmptyState
            icon={<TrashIcon />}
            title="Silinmiş menü yok"
            description="Soft-delete edilmiş menü bulunamadı."
          />
        ) : (
          <PanelBolumKarti noPadding>
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b border-border text-left">
                  <th className="px-5 py-3 text-[11px] font-extrabold uppercase tracking-wide text-muted">Menü</th>
                  <th className="px-5 py-3 text-[11px] font-extrabold uppercase tracking-wide text-muted">İşletme</th>
                  <th className="px-5 py-3 text-[11px] font-extrabold uppercase tracking-wide text-muted">Silinme Tarihi</th>
                  <th className="px-5 py-3 text-[11px] font-extrabold uppercase tracking-wide text-muted">İşlem</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-border">
                {list.map((m: any) => (
                  <tr key={m.id} className="hover:bg-black/2">
                    <td className="px-5 py-3">
                      <p className="font-bold text-textStrong">{m.title ?? '—'}</p>
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
                      <AdminMenuGeriAlDugmesi menuId={String(m.id)} />
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
                    <a href={`?page=${pageNum - 1}`} className="rounded-lg border border-border px-3 py-1 text-xs font-bold text-textStrong hover:bg-black/2">
                      ← Önceki
                    </a>
                  )}
                  {pageNum < totalPages && (
                    <a href={`?page=${pageNum + 1}`} className="rounded-lg border border-border px-3 py-1 text-xs font-bold text-textStrong hover:bg-black/2">
                      Sonraki →
                    </a>
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

