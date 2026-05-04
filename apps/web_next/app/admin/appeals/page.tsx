import type { Metadata } from 'next';
import { createSupabaseServerClient } from '@/src/lib/supabaseServer';
import { PanelPageHeader } from '@/src/ui/layout/panel-page-header';
import { PanelContentSurface, PanelSectionCard } from '@/src/ui/layout/panel-section-card';
import { PanelEmptyState } from '@/src/ui/components/panel-empty-state';

export const metadata: Metadata = {
  title: 'İtirazlar | Admin Panel',
  robots: { index: false, follow: false },
};

type Props = { searchParams: Promise<{ status?: string; page?: string }> };
const PAGE_SIZE = 40;

const STATUS_LABELS: Record<string, string> = {
  pending: 'Bekliyor',
  approved: 'Onaylandı',
  rejected: 'Reddedildi',
};

export default async function AdminAppealsPage({ searchParams }: Props) {
  const { status = 'pending', page = '1' } = await searchParams;
  const pageNum = Math.max(1, parseInt(page, 10));
  const offset = (pageNum - 1) * PAGE_SIZE;

  const supabase = await createSupabaseServerClient();

  let list: any[] = [];
  let count: number | null = 0;
  let totalPages = 0;
  let fetchError = false;

  try {
    const query = (supabase as any)
      .from('claim_appeals')
      .select('id, claim_id, user_id, reason, status, created_at', { count: 'exact' })
      .order('created_at', { ascending: false })
      .range(offset, offset + PAGE_SIZE - 1);

    const res = await (status !== 'all' ? query.eq('status', status) : query) as { data: any[] | null; count: number | null; error: any };

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
        title="İtirazlar"
        description={fetchError ? 'Tablo erişilemiyor' : `${count ?? 0} kayıt`}
      />
      <PanelContentSurface className="pt-6">
        {fetchError ? (
          <PanelEmptyState
            icon={<FlagIcon />}
            title="Bu özellik yakında aktif edilecek"
            description="claim_appeals tablosu henüz yapılandırılmamış olabilir."
          />
        ) : (
          <div className="flex flex-col gap-4">
            {/* Status filter */}
            <form method="get" className="flex gap-2">
              {[
                { value: 'pending', label: 'Bekliyor' },
                { value: 'approved', label: 'Onaylandı' },
                { value: 'rejected', label: 'Reddedildi' },
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
                      : 'border border-border bg-card text-muted hover:text-textStrong'
                  }`}
                >
                  {label}
                </button>
              ))}
            </form>

            {list.length === 0 ? (
              <PanelEmptyState icon={<FlagIcon />} title="İtiraz yok" />
            ) : (
              <PanelSectionCard noPadding>
                <table className="w-full text-sm">
                  <thead>
                    <tr className="border-b border-border text-left">
                      <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">Talep ID</th>
                      <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">Kullanıcı</th>
                      <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">Neden</th>
                      <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">Durum</th>
                      <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">Tarih</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-border">
                    {list.map((a: any) => (
                      <tr key={a.id} className="hover:bg-black/[0.02]">
                        <td className="px-5 py-3 font-mono text-xs text-muted">
                          {a.claim_id ? String(a.claim_id).slice(0, 8) + '…' : '—'}
                        </td>
                        <td className="px-5 py-3 font-mono text-xs text-muted">
                          {a.user_id ? String(a.user_id).slice(0, 8) + '…' : '—'}
                        </td>
                        <td className="max-w-[280px] px-5 py-3 text-muted">
                          <p className="line-clamp-2">{a.reason ?? '—'}</p>
                        </td>
                        <td className="px-5 py-3">
                          <span
                            className={`rounded-full px-2 py-0.5 text-[10px] font-[800] ${
                              a.status === 'approved'
                                ? 'bg-green-50 text-green-700'
                                : a.status === 'rejected'
                                ? 'bg-red-50 text-red-700'
                                : 'bg-amber-50 text-amber-700'
                            }`}
                          >
                            {STATUS_LABELS[a.status] ?? a.status}
                          </span>
                        </td>
                        <td className="px-5 py-3 text-xs text-muted">
                          {new Date(a.created_at).toLocaleDateString('tr-TR')}
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
                        <a href={`?status=${status}&page=${pageNum - 1}`} className="rounded-lg border border-border px-3 py-1 text-xs font-[700] text-textStrong hover:bg-black/[0.02]">
                          ← Önceki
                        </a>
                      )}
                      {pageNum < totalPages && (
                        <a href={`?status=${status}&page=${pageNum + 1}`} className="rounded-lg border border-border px-3 py-1 text-xs font-[700] text-textStrong hover:bg-black/[0.02]">
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

function FlagIcon() {
  return (
    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M4 15s1-1 4-1 5 2 8 2 4-1 4-1V3s-1 1-4 1-5-2-8-2-4 1-4 1z" />
      <line x1="4" y1="22" x2="4" y2="15" />
    </svg>
  );
}
