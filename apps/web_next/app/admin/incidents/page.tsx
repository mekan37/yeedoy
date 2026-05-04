import type { Metadata } from 'next';
import { createSupabaseServerClient } from '@/src/lib/supabaseServer';
import { PanelPageHeader } from '@/src/ui/layout/panel-page-header';
import { PanelContentSurface, PanelSectionCard } from '@/src/ui/layout/panel-section-card';
import { PanelEmptyState } from '@/src/ui/components/panel-empty-state';

export const metadata: Metadata = {
  title: 'Olay Merkezi | Admin Panel',
  robots: { index: false, follow: false },
};

type Props = { searchParams: Promise<{ severity?: string; status?: string; page?: string }> };
const PAGE_SIZE = 40;

const SEVERITY_LABELS: Record<string, string> = {
  low: 'Düşük',
  medium: 'Orta',
  high: 'Yüksek',
  critical: 'Kritik',
};

const STATUS_LABELS: Record<string, string> = {
  open: 'Açık',
  investigating: 'İnceleniyor',
  resolved: 'Çözüldü',
  closed: 'Kapatıldı',
};

export default async function AdminIncidentsPage({ searchParams }: Props) {
  const { severity = 'all', status = 'open', page = '1' } = await searchParams;
  const pageNum = Math.max(1, parseInt(page, 10));
  const offset = (pageNum - 1) * PAGE_SIZE;

  const supabase = await createSupabaseServerClient();

  let list: any[] = [];
  let count: number | null = 0;
  let totalPages = 0;
  let fetchError = false;

  try {
    let query = (supabase as any)
      .from('admin_incidents')
      .select('id, incident_type, severity, status, description, created_at, resolved_at', { count: 'exact' })
      .order('created_at', { ascending: false })
      .range(offset, offset + PAGE_SIZE - 1);

    if (status !== 'all') query = query.eq('status', status);
    if (severity !== 'all') query = query.eq('severity', severity);

    const res = await query as { data: any[] | null; count: number | null; error: any };

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
        title="Olay Merkezi"
        description={fetchError ? 'Tablo erişilemiyor' : `${count ?? 0} olay`}
      />
      <PanelContentSurface className="pt-6">
        {fetchError ? (
          <PanelEmptyState
            icon={<AlertIcon />}
            title="Bu özellik yakında aktif edilecek"
            description="admin_incidents tablosu henüz yapılandırılmamış olabilir."
          />
        ) : (
          <div className="flex flex-col gap-4">
            {/* Filters */}
            <div className="flex flex-wrap gap-3">
              <form method="get" className="flex gap-2">
                <input type="hidden" name="severity" value={severity} />
                {[
                  { value: 'open', label: 'Açık' },
                  { value: 'investigating', label: 'İnceleniyor' },
                  { value: 'resolved', label: 'Çözüldü' },
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

              <form method="get" className="flex gap-2">
                <input type="hidden" name="status" value={status} />
                {[
                  { value: 'all', label: 'Tüm Ciddiyet' },
                  { value: 'critical', label: 'Kritik' },
                  { value: 'high', label: 'Yüksek' },
                  { value: 'medium', label: 'Orta' },
                  { value: 'low', label: 'Düşük' },
                ].map(({ value, label }) => (
                  <button
                    key={value}
                    type="submit"
                    name="severity"
                    value={value}
                    className={`rounded-lg px-3 py-1.5 text-xs font-[700] transition-colors ${
                      severity === value
                        ? 'bg-primary text-white'
                        : 'border border-border bg-card text-muted hover:text-textStrong'
                    }`}
                  >
                    {label}
                  </button>
                ))}
              </form>
            </div>

            {list.length === 0 ? (
              <PanelEmptyState icon={<AlertIcon />} title="Olay yok" />
            ) : (
              <PanelSectionCard noPadding>
                <table className="w-full text-sm">
                  <thead>
                    <tr className="border-b border-border text-left">
                      <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">Olay Tipi</th>
                      <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">Ciddiyet</th>
                      <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">Durum</th>
                      <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">Açıklama</th>
                      <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">Oluşturma Tarihi</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-border">
                    {list.map((inc: any) => (
                      <tr key={inc.id} className="hover:bg-black/[0.02]">
                        <td className="px-5 py-3 font-[700] text-textStrong">
                          {inc.incident_type ?? '—'}
                        </td>
                        <td className="px-5 py-3">
                          <span
                            className={`rounded-full px-2 py-0.5 text-[10px] font-[800] ${
                              inc.severity === 'critical'
                                ? 'bg-red-100 text-red-700'
                                : inc.severity === 'high'
                                ? 'bg-orange-50 text-orange-700'
                                : inc.severity === 'medium'
                                ? 'bg-amber-50 text-amber-700'
                                : 'bg-zinc-100 text-zinc-500'
                            }`}
                          >
                            {SEVERITY_LABELS[inc.severity] ?? inc.severity ?? '—'}
                          </span>
                        </td>
                        <td className="px-5 py-3">
                          <span
                            className={`rounded-full px-2 py-0.5 text-[10px] font-[800] ${
                              inc.status === 'resolved' || inc.status === 'closed'
                                ? 'bg-green-50 text-green-700'
                                : inc.status === 'investigating'
                                ? 'bg-blue-50 text-blue-700'
                                : 'bg-amber-50 text-amber-700'
                            }`}
                          >
                            {STATUS_LABELS[inc.status] ?? inc.status ?? '—'}
                          </span>
                        </td>
                        <td className="max-w-[300px] px-5 py-3 text-muted">
                          <p className="line-clamp-2">{inc.description ?? '—'}</p>
                        </td>
                        <td className="px-5 py-3 text-xs text-muted">
                          {new Date(inc.created_at).toLocaleDateString('tr-TR')}
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
                          href={`?severity=${severity}&status=${status}&page=${pageNum - 1}`}
                          className="rounded-lg border border-border px-3 py-1 text-xs font-[700] text-textStrong hover:bg-black/[0.02]"
                        >
                          ← Önceki
                        </a>
                      )}
                      {pageNum < totalPages && (
                        <a
                          href={`?severity=${severity}&status=${status}&page=${pageNum + 1}`}
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

function AlertIcon() {
  return (
    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z" />
      <line x1="12" y1="9" x2="12" y2="13" />
      <line x1="12" y1="17" x2="12.01" y2="17" />
    </svg>
  );
}
