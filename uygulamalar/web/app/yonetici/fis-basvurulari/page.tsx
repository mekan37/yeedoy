import type { Metadata } from 'next';
import Link from 'next/link';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { PanelSayfaBasligi } from '@/src/ui/yerlesim/panel-page-header';
import { PanelIcerikYuzeyi, PanelBolumKarti } from '@/src/ui/yerlesim/panel-section-card';
import { PanelEmptyState } from '@/src/ui/bilesenler/panel-bos-durum';

export const metadata: Metadata = {
  title: 'Fiş Başvuruları | Yonetici Paneli',
  robots: { index: false, follow: false },
};

type Props = { searchParams: Promise<{ status?: string; page?: string }> };
const PAGE_SIZE = 40;

const STATUS_LABELS: Record<string, string> = {
  pending: 'Bekliyor',
  reviewed: 'İncelendi',
  needs_followup: 'Takip Gerekli',
};

type ReceiptStatus = 'pending' | 'reviewed' | 'needs_followup' | 'all';

type ReceiptRow = {
  receipt_id: string;
  created_at: string;
  user_id: string | null;
  business_id: string | null;
  business_name: string | null;
  city: string | null;
  district: string | null;
  chain_name: string | null;
  image_url: string | null;
  matches_count: number | null;
  review_status: string;
  review_note: string | null;
};

const STATUS_FILTERS: Array<{ value: ReceiptStatus; label: string }> = [
  { value: 'pending', label: 'Bekliyor' },
  { value: 'reviewed', label: 'İncelendi' },
  { value: 'needs_followup', label: 'Takip Gerekli' },
  { value: 'all', label: 'Tümü' },
];

export default async function AdminReceiptSubmissionsPage({ searchParams }: Props) {
  const { status: rawStatus = 'pending', page = '1' } = await searchParams;
  const status = normalizeStatus(rawStatus);
  const pageNum = Math.max(1, parseInt(page, 10));
  const offset = (pageNum - 1) * PAGE_SIZE;

  const supabase = await createSupabaseServerClient();

  const { list, count, hasNextPage, fetchError } = await getReceiptRows(supabase as any, {
    status,
    offset,
  });
  const totalPages = count != null ? Math.ceil(count / PAGE_SIZE) : pageNum + (hasNextPage ? 1 : 0);

  return (
    <div className="flex flex-col">
      <PanelSayfaBasligi
        eyebrow="Admin"
        title="Fiş Başvuruları"
        description={fetchError ? 'Fiş başvuruları okunamadı' : count != null ? `${count} başvuru` : `${list.length} başvuru`}
      />
      <PanelIcerikYuzeyi className="pt-6">
        {fetchError ? (
          <PanelEmptyState
            icon={<ReceiptIcon />}
            title="Fiş başvuruları okunamadı"
            description="receipt_submissions yapısı var, ancak listeleme RPC'si veya yetki kontrolü başarısız oldu."
          />
        ) : (
          <div className="flex flex-col gap-4">
            <form method="get" className="flex gap-2">
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

            {list.length === 0 ? (
              <PanelEmptyState icon={<ReceiptIcon />} title="Başvuru yok" />
            ) : (
              <PanelBolumKarti noPadding>
                <table className="w-full text-sm">
                  <thead>
                    <tr className="border-b border-border text-left">
                      <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">Kullanıcı</th>
                      <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">İşletme</th>
                      <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">Eşleşme</th>
                      <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">Durum</th>
                      <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">Tarih</th>
                      <th className="px-5 py-3 text-right text-[11px] font-[800] uppercase tracking-wide text-muted">Fiş</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-border">
                    {list.map((r) => (
                      <tr key={r.receipt_id} className="hover:bg-black/[0.02]">
                        <td className="px-5 py-3 font-mono text-xs text-muted">
                          {r.user_id ? String(r.user_id).slice(0, 8) + '…' : '—'}
                        </td>
                        <td className="px-5 py-3">
                          <p className="font-[700] text-textStrong">{r.business_name ?? '—'}</p>
                          <p className="text-xs text-muted">{[r.district, r.city, r.chain_name].filter(Boolean).join(' · ')}</p>
                        </td>
                        <td className="px-5 py-3 font-[800] text-textStrong">
                          {r.matches_count ?? 0} ürün
                        </td>
                        <td className="px-5 py-3">
                          <span
                            className={`rounded-full px-2 py-0.5 text-[10px] font-[800] ${
                              r.review_status === 'reviewed'
                                ? 'bg-green-50 text-green-700'
                                : r.review_status === 'needs_followup'
                                ? 'bg-blue-50 text-blue-700'
                                : 'bg-amber-50 text-amber-700'
                            }`}
                          >
                            {STATUS_LABELS[r.review_status] ?? r.review_status}
                          </span>
                          {r.review_note && <p className="mt-1 max-w-xs truncate text-xs text-muted">{r.review_note}</p>}
                        </td>
                        <td className="px-5 py-3 text-xs text-muted">
                          {new Date(r.created_at).toLocaleDateString('tr-TR')}
                        </td>
                        <td className="px-5 py-3 text-right">
                          {r.image_url ? (
                            <a
                              href={r.image_url}
                              target="_blank"
                              rel="noreferrer"
                              className="inline-flex min-h-9 items-center rounded-lg border border-border px-3 text-xs font-[800] text-textStrong transition-colors hover:border-primary/30 hover:text-primary"
                            >
                              Görüntüle
                            </a>
                          ) : (
                            <span className="text-xs text-muted">—</span>
                          )}
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
                        <Link href={`?status=${status}&page=${pageNum - 1}`} className="rounded-lg border border-border px-3 py-1 text-xs font-[700] text-textStrong hover:bg-black/[0.02]">
                          ← Önceki
                        </Link>
                      )}
                      {pageNum < totalPages && (
                        <Link href={`?status=${status}&page=${pageNum + 1}`} className="rounded-lg border border-border px-3 py-1 text-xs font-[700] text-textStrong hover:bg-black/[0.02]">
                          Sonraki →
                        </Link>
                      )}
                    </div>
                  </div>
                )}
              </PanelBolumKarti>
            )}
          </div>
        )}
      </PanelIcerikYuzeyi>
    </div>
  );
}

async function getReceiptRows(
  supabase: any,
  input: { status: ReceiptStatus; offset: number },
): Promise<{ list: ReceiptRow[]; count: number | null; hasNextPage: boolean; fetchError: boolean }> {
  const reviewStatus = input.status === 'all' ? null : input.status;

  const [{ data, error }, summary] = await Promise.all([
    supabase.rpc('admin_list_receipt_submissions_v2', {
      p_query: null,
      p_review_status: reviewStatus,
      p_only_unmatched: false,
      p_limit: PAGE_SIZE + 1,
      p_offset: input.offset,
    }),
    supabase.rpc('admin_get_receipt_submission_summary_v1', {
      p_query: null,
      p_review_status: reviewStatus,
      p_only_unmatched: false,
    }),
  ]);

  if (error) {
    return { list: [], count: 0, hasNextPage: false, fetchError: true };
  }

  const rows = ((data ?? []) as ReceiptRow[]);
  const count = Array.isArray(summary.data) && summary.data[0]?.total_count != null
    ? Number(summary.data[0].total_count)
    : null;

  return {
    list: rows.slice(0, PAGE_SIZE),
    count,
    hasNextPage: rows.length > PAGE_SIZE,
    fetchError: false,
  };
}

function normalizeStatus(value: string): ReceiptStatus {
  return STATUS_FILTERS.some((filter) => filter.value === value) ? (value as ReceiptStatus) : 'pending';
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

