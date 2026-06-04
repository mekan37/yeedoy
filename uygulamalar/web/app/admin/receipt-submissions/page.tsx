import type { Metadata } from 'next';
import Link from 'next/link';
import { PanelPageHeader } from '@/src/ui/layout/panel-page-header';
import { PanelContentSurface, PanelSectionCard } from '@/src/ui/layout/panel-section-card';
import { PanelEmptyState } from '@/src/ui/components/panel-empty-state';
import {
  listAdminFisGonderimleri,
  getAdminFisGonderimOzeti,
  REVIEW_STATUS_LABELS,
  REVIEW_STATUS_STYLES,
  type FisGonderimDurumu,
} from '@/src/lib/veri/admin/fis-gonderimleri';

export const metadata: Metadata = {
  title: 'Fiş Başvuruları | Admin Panel',
  robots: { index: false, follow: false },
};

type Props = { searchParams: Promise<{ status?: string; page?: string }> };
const PAGE_SIZE = 40;

const STATUS_FILTERS: Array<{ value: FisGonderimDurumu; label: string }> = [
  { value: 'pending', label: 'Bekliyor' },
  { value: 'needs_followup', label: 'Takip Gerekli' },
  { value: 'reviewed', label: 'İncelendi' },
  { value: 'all', label: 'Tümü' },
];

function normalizeStatus(value: string): FisGonderimDurumu {
  return STATUS_FILTERS.some((f) => f.value === value)
    ? (value as FisGonderimDurumu)
    : 'pending';
}

export default async function AdminReceiptSubmissionsPage({ searchParams }: Props) {
  const { status: rawStatus = 'pending', page = '1' } = await searchParams;
  const status = normalizeStatus(rawStatus);
  const pageNum = Math.max(1, parseInt(page, 10));
  const offset = (pageNum - 1) * PAGE_SIZE;

  const [{ list, count, hasNextPage, fetchError }, ozet] = await Promise.all([
    listAdminFisGonderimleri({
      reviewStatus: status,
      limit: PAGE_SIZE + 1,
      offset,
    }),
    getAdminFisGonderimOzeti(),
  ]);

  const totalPages =
    count != null
      ? Math.ceil(count / PAGE_SIZE)
      : pageNum + (hasNextPage ? 1 : 0);

  return (
    <div className="flex flex-col">
      <PanelPageHeader
        eyebrow="Admin"
        title="Fiş Başvuruları"
        description={
          fetchError
            ? 'Tablo erişilemiyor'
            : count != null
              ? `${count} başvuru`
              : `${list.length} başvuru`
        }
      />
      <PanelContentSurface className="pt-6">
        <div className="flex flex-col gap-5">

          {/* Summary cards */}
          {!fetchError && (
            <div className="grid grid-cols-2 gap-3 sm:grid-cols-4">
              {[
                { label: 'Bekliyor', value: ozet.pending_count, color: 'text-amber-600' },
                { label: 'Takip', value: ozet.needs_followup_count, color: 'text-blue-600' },
                { label: 'İncelendi', value: ozet.reviewed_count, color: 'text-green-600' },
                { label: 'Son 24 Saat', value: ozet.recent_24h_count, color: 'text-textStrong' },
              ].map(({ label, value, color }) => (
                <div key={label} className="rounded-xl border border-border bg-card px-4 py-3 shadow-sm">
                  <p className="text-[11px] font-[700] uppercase tracking-wide text-muted">{label}</p>
                  <p className={`mt-1 text-2xl font-[900] ${color}`}>{value}</p>
                </div>
              ))}
            </div>
          )}

          {/* Status filter */}
          <form method="get" className="flex flex-wrap gap-2">
            {STATUS_FILTERS.map(({ value, label }) => (
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

          {fetchError ? (
            <PanelEmptyState
              icon={<ReceiptIcon />}
              title="Bu özellik yakında aktif edilecek"
              description="receipt_submissions tablosu henüz yapılandırılmamış olabilir."
            />
          ) : list.length === 0 ? (
            <PanelEmptyState icon={<ReceiptIcon />} title="Başvuru yok" />
          ) : (
            <PanelSectionCard noPadding>
              <div className="overflow-x-auto">
                <table className="w-full text-sm">
                  <thead>
                    <tr className="border-b border-border text-left">
                      <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">Kullanıcı</th>
                      <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">İşletme</th>
                      <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">Eşleşme</th>
                      <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">Durum</th>
                      <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">Tarih</th>
                      <th className="px-5 py-3 text-center text-[11px] font-[800] uppercase tracking-wide text-muted">Fiş</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-border">
                    {list.map((r) => (
                      <tr key={r.receipt_id} className="hover:bg-black/[0.02]">
                        <td className="px-5 py-3 font-mono text-xs text-muted">
                          {r.submitter_display}
                        </td>
                        <td className="px-5 py-3">
                          <p className="font-[700] text-textStrong">{r.business_name ?? '—'}</p>
                          <p className="text-xs text-muted">
                            {[r.district, r.city, r.chain_name].filter(Boolean).join(' · ')}
                          </p>
                        </td>
                        <td className="px-5 py-3">
                          <span className={`text-sm font-[800] ${r.matches_count === 0 ? 'text-red-500' : 'text-textStrong'}`}>
                            {r.matches_count} ürün
                          </span>
                        </td>
                        <td className="px-5 py-3">
                          <span
                            className={`rounded-full px-2 py-0.5 text-[10px] font-[800] ${
                              REVIEW_STATUS_STYLES[r.review_status] ?? 'bg-zinc-100 text-zinc-500'
                            }`}
                          >
                            {REVIEW_STATUS_LABELS[r.review_status] ?? r.review_status}
                          </span>
                          {r.review_note && (
                            <p className="mt-1 max-w-[180px] truncate text-xs text-muted">{r.review_note}</p>
                          )}
                        </td>
                        <td className="px-5 py-3 text-xs text-muted">
                          {new Date(r.created_at).toLocaleDateString('tr-TR')}
                        </td>
                        <td className="px-5 py-3 text-center">
                          {r.image_url ? (
                            <a
                              href={r.image_url}
                              target="_blank"
                              rel="noreferrer"
                              className="inline-flex min-h-8 items-center gap-1 rounded-lg border border-border px-2.5 text-xs font-[800] text-textStrong transition-colors hover:border-primary/30 hover:text-primary"
                            >
                              <ReceiptIcon size={14} />
                              Gör
                            </a>
                          ) : (
                            <span className="text-xs text-muted">—</span>
                          )}
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>

              {totalPages > 1 && (
                <div className="flex items-center justify-between border-t border-border px-5 py-3">
                  <span className="text-xs text-muted">Sayfa {pageNum} / {totalPages}</span>
                  <div className="flex gap-2">
                    {pageNum > 1 && (
                      <Link
                        href={`?status=${status}&page=${pageNum - 1}`}
                        className="rounded-lg border border-border px-3 py-1 text-xs font-[700] text-textStrong hover:bg-black/[0.02]"
                      >
                        Önceki
                      </Link>
                    )}
                    {pageNum < totalPages && (
                      <Link
                        href={`?status=${status}&page=${pageNum + 1}`}
                        className="rounded-lg border border-border px-3 py-1 text-xs font-[700] text-textStrong hover:bg-black/[0.02]"
                      >
                        Sonraki
                      </Link>
                    )}
                  </div>
                </div>
              )}
            </PanelSectionCard>
          )}
        </div>
      </PanelContentSurface>
    </div>
  );
}

function ReceiptIcon({ size = 20 }: { size?: number }) {
  return (
    <svg
      width={size}
      height={size}
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth="2"
      strokeLinecap="round"
      strokeLinejoin="round"
    >
      <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z" />
      <polyline points="14 2 14 8 20 8" />
      <line x1="16" y1="13" x2="8" y2="13" />
      <line x1="16" y1="17" x2="8" y2="17" />
      <polyline points="10 9 9 9 8 9" />
    </svg>
  );
}
