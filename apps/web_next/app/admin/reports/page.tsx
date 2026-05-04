import type { Metadata } from 'next';
import { createSupabaseServerClient } from '@/src/lib/supabaseServer';
import { PanelPageHeader } from '@/src/ui/layout/panel-page-header';
import { PanelContentSurface, PanelSectionCard } from '@/src/ui/layout/panel-section-card';
import { PanelEmptyState } from '@/src/ui/components/panel-empty-state';

export const metadata: Metadata = {
  title: 'Raporlar | Admin Panel',
  robots: { index: false, follow: false },
};

type Props = { searchParams: Promise<{ status?: string; page?: string }> };
const PAGE_SIZE = 40;

const STATUS_MAP: Record<string, { label: string; className: string }> = {
  open: { label: 'Açık', className: 'bg-amber-50 text-amber-700' },
  reviewing: { label: 'İnceleniyor', className: 'bg-blue-50 text-blue-700' },
  resolved: { label: 'Çözüldü', className: 'bg-green-50 text-green-700' },
  dismissed: { label: 'Reddedildi', className: 'bg-zinc-100 text-zinc-500' },
};

export default async function AdminReportsPage({ searchParams }: Props) {
  const { status = 'open', page = '1' } = await searchParams;
  const pageNum = Math.max(1, parseInt(page, 10));
  const offset = (pageNum - 1) * PAGE_SIZE;

  const supabase = await createSupabaseServerClient();

  let query = (supabase as any)
    .from('reports')
    .select('id, target_type, reason, details, status, created_at, assigned_to, business_id, review_id', { count: 'exact' })
    .order('created_at', { ascending: false })
    .range(offset, offset + PAGE_SIZE - 1);

  if (status !== 'all') {
    query = query.eq('status', status);
  }

  const { data: reports, count } = await query;
  const list = (reports ?? []) as any[];
  const totalPages = Math.ceil((count ?? 0) / PAGE_SIZE);

  return (
    <div className="flex flex-col">
      <PanelPageHeader
        eyebrow="Admin"
        title="Raporlar"
        description={count != null ? `${count.toLocaleString('tr-TR')} rapor` : ''}
      />
      <PanelContentSurface className="pt-6">
        {/* Status filter */}
        <form method="get" className="mb-4 flex gap-2">
          {[
            { value: 'open', label: 'Açık' },
            { value: 'reviewing', label: 'İncelemede' },
            { value: 'resolved', label: 'Çözüldü' },
            { value: 'dismissed', label: 'Reddedildi' },
            { value: 'all', label: 'Tümü' },
          ].map(({ value, label }) => (
            <button
              key={value}
              type="submit"
              name="status"
              value={value}
              className={`rounded-lg px-3 py-1.5 text-xs font-[700] transition-colors ${
                status === value
                  ? 'bg-primary text-white'
                  : 'bg-card border border-border text-muted hover:text-textStrong'
              }`}
            >
              {label}
            </button>
          ))}
        </form>

        {list.length === 0 ? (
          <PanelEmptyState icon={<FlagIcon />} title="Rapor bulunamadı" />
        ) : (
          <PanelSectionCard noPadding>
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b border-border text-left">
                  <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">Hedef</th>
                  <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">Neden</th>
                  <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">Detay</th>
                  <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">Durum</th>
                  <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">Tarih</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-border">
                {list.map((r: any) => {
                  const statusInfo = STATUS_MAP[r.status] ?? STATUS_MAP['open'];
                  return (
                    <tr key={r.id}>
                      <td className="px-5 py-3 font-[700] capitalize text-textStrong">{r.target_type}</td>
                      <td className="px-5 py-3 text-muted">{r.reason}</td>
                      <td className="max-w-xs px-5 py-3">
                        <p className="line-clamp-2 text-xs text-muted">{r.details ?? '—'}</p>
                      </td>
                      <td className="px-5 py-3">
                        <span className={`rounded-full px-2 py-0.5 text-[10px] font-[800] ${statusInfo.className}`}>
                          {statusInfo.label}
                        </span>
                      </td>
                      <td className="px-5 py-3 text-xs text-muted">
                        {new Date(r.created_at).toLocaleDateString('tr-TR')}
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
            {totalPages > 1 && (
              <div className="flex items-center justify-between border-t border-border px-5 py-3">
                <span className="text-xs text-muted">Sayfa {pageNum} / {totalPages}</span>
                <div className="flex gap-2">
                  {pageNum > 1 && (
                    <a href={`?status=${status}&page=${pageNum - 1}`}
                      className="rounded-lg border border-border px-3 py-1 text-xs font-[700] text-textStrong hover:bg-black/[0.02]">
                      ← Önceki
                    </a>
                  )}
                  {pageNum < totalPages && (
                    <a href={`?status=${status}&page=${pageNum + 1}`}
                      className="rounded-lg border border-border px-3 py-1 text-xs font-[700] text-textStrong hover:bg-black/[0.02]">
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

function FlagIcon() {
  return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M4 15s1-1 4-1 5 2 8 2 4-1 4-1V3s-1 1-4 1-5-2-8-2-4 1-4 1z" /><line x1="4" y1="22" x2="4" y2="15" /></svg>;
}
