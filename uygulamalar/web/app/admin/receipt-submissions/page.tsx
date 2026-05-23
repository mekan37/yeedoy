import type { Metadata } from 'next';
import { createSupabaseServerClient } from '@/src/lib/supabaseServer';
import { PanelPageHeader } from '@/src/ui/layout/panel-page-header';
import { PanelContentSurface, PanelSectionCard } from '@/src/ui/layout/panel-section-card';
import { PanelEmptyState } from '@/src/ui/components/panel-empty-state';

export const metadata: Metadata = {
  title: 'Fiş Başvuruları | Admin Panel',
  robots: { index: false, follow: false },
};

type Props = { searchParams: Promise<{ status?: string; page?: string }> };
const PAGE_SIZE = 40;

const STATUS_LABELS: Record<string, string> = {
  pending: 'Bekliyor',
  approved: 'Onaylandı',
  rejected: 'Reddedildi',
};

function formatAmount(cents: number | null, currency: string | null) {
  if (cents == null) return '—';
  return new Intl.NumberFormat('tr-TR', {
    style: 'currency',
    currency: currency ?? 'TRY',
    minimumFractionDigits: 2,
  }).format(cents / 100);
}

export default async function AdminReceiptSubmissionsPage({ searchParams }: Props) {
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
      .from('receipt_submissions')
      .select(
        'id, user_id, business_id, amount_cents, currency, status, created_at, ' +
          'businesses(name, city)',
        { count: 'exact' },
      )
      .order('created_at', { ascending: false })
      .range(offset, offset + PAGE_SIZE - 1);

    const res = await (status !== 'all' ? query.eq('status', status) : query) as {
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
        title="Fiş Başvuruları"
        description={fetchError ? 'Tablo erişilemiyor' : `${count ?? 0} başvuru`}
      />
      <PanelContentSurface className="pt-6">
        {fetchError ? (
          <PanelEmptyState
            icon={<ReceiptIcon />}
            title="Bu özellik yakında aktif edilecek"
            description="receipt_submissions tablosu henüz yapılandırılmamış olabilir."
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
              <PanelEmptyState icon={<ReceiptIcon />} title="Başvuru yok" />
            ) : (
              <PanelSectionCard noPadding>
                <table className="w-full text-sm">
                  <thead>
                    <tr className="border-b border-border text-left">
                      <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">Kullanıcı</th>
                      <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">İşletme</th>
                      <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">Tutar</th>
                      <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">Durum</th>
                      <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">Tarih</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-border">
                    {list.map((r: any) => (
                      <tr key={r.id} className="hover:bg-black/[0.02]">
                        <td className="px-5 py-3 font-mono text-xs text-muted">
                          {r.user_id ? String(r.user_id).slice(0, 8) + '…' : '—'}
                        </td>
                        <td className="px-5 py-3">
                          <p className="font-[700] text-textStrong">{r.businesses?.name ?? '—'}</p>
                          <p className="text-xs text-muted">{r.businesses?.city ?? ''}</p>
                        </td>
                        <td className="px-5 py-3 font-[800] text-textStrong">
                          {formatAmount(r.amount_cents, r.currency)}
                        </td>
                        <td className="px-5 py-3">
                          <span
                            className={`rounded-full px-2 py-0.5 text-[10px] font-[800] ${
                              r.status === 'approved'
                                ? 'bg-green-50 text-green-700'
                                : r.status === 'rejected'
                                ? 'bg-red-50 text-red-700'
                                : 'bg-amber-50 text-amber-700'
                            }`}
                          >
                            {STATUS_LABELS[r.status] ?? r.status}
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

function ReceiptIcon() {
  return (
    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z" />
      <polyline points="14 2 14 8 20 8" />
      <line x1="16" y1="13" x2="8" y2="13" />
      <line x1="16" y1="17" x2="8" y2="17" />
      <polyline points="10 9 9 9 8 9" />
    </svg>
  );
}
