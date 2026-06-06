import type { Metadata } from 'next';
import { redirect } from 'next/navigation';
import Link from 'next/link';
import { checkAdminAccess } from '@/src/lib/auth/admin-guard';
import {
  listAdminItirazlar,
  APPEAL_STATUS_LABELS,
  APPEAL_STATUS_STYLES,
  SOURCE_TYPE_LABELS,
  type AppealStatus,
} from '@/src/lib/veri/admin/itirazlar';
import { PanelPageHeader } from '@/src/ui/layout/panel-page-header';
import { PanelContentSurface, PanelSectionCard } from '@/src/ui/layout/panel-section-card';
import { PanelEmptyState } from '@/src/ui/components/panel-empty-state';
import { decideAppealAction } from './appeal-actions';

export const metadata: Metadata = {
  title: 'İtirazlar | Admin Panel',
  robots: { index: false, follow: false },
};

type Props = { searchParams: Promise<{ status?: string; page?: string }> };

const PAGE_SIZE = 40;

const STATUS_FILTERS: Array<{ value: AppealStatus | 'all'; label: string }> = [
  { value: 'pending', label: 'Bekliyor' },
  { value: 'approved', label: 'Onaylandı' },
  { value: 'rejected', label: 'Reddedildi' },
  { value: 'all', label: 'Tümü' },
];

const ALLOWED_STATUSES = ['pending', 'approved', 'rejected', 'all'] as const;
type AllowedStatus = (typeof ALLOWED_STATUSES)[number];

function normalizeStatus(value: string | undefined): AllowedStatus {
  if (value && (ALLOWED_STATUSES as readonly string[]).includes(value)) {
    return value as AllowedStatus;
  }
  return 'pending';
}

export default async function AdminAppealsPage({ searchParams }: Props) {
  const guard = await checkAdminAccess();
  if (!guard.authorized) {
    redirect('/forbidden');
  }

  const { status: rawStatus, page = '1' } = await searchParams;
  const status = normalizeStatus(rawStatus);
  const pageNum = Math.max(1, parseInt(page, 10));
  const offset = (pageNum - 1) * PAGE_SIZE;

  const { list, count, fetchError } = await listAdminItirazlar({
    status,
    limit: PAGE_SIZE,
    offset,
  });

  const totalFromCount = count != null ? count : null;
  const totalPages =
    totalFromCount != null
      ? Math.ceil(totalFromCount / PAGE_SIZE)
      : list.length === PAGE_SIZE
        ? pageNum + 1
        : pageNum;

  const descriptionText = fetchError
    ? 'Veri çekilemedi'
    : count != null
      ? `${count} itiraz`
      : `${list.length} itiraz`;

  return (
    <div className="flex flex-col">
      <PanelPageHeader
        eyebrow="Admin"
        title="İtirazlar"
        description={descriptionText}
      />
      <PanelContentSurface className="pt-6">
        <div className="flex flex-col gap-5">

          {/* Status filtresi */}
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
              icon={<FlagIcon />}
              title="Veriler yüklenemedi"
              description="admin_list_moderation_appeals_v1 RPC erişilemedi. Lütfen tekrar deneyin."
            />
          ) : list.length === 0 ? (
            <PanelEmptyState
              icon={<FlagIcon />}
              title="İtiraz yok"
              description={
                status === 'pending'
                  ? 'Bekleyen itiraz bulunmuyor.'
                  : `${APPEAL_STATUS_LABELS[status as AppealStatus | 'all']} durumunda itiraz yok.`
              }
            />
          ) : (
            <PanelSectionCard noPadding>
              <div className="overflow-x-auto">
                <table className="w-full text-sm">
                  <thead>
                    <tr className="border-b border-border text-left">
                      <th className="px-4 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">
                        Başvuran
                      </th>
                      <th className="px-4 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">
                        Kaynak
                      </th>
                      <th className="px-4 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">
                        Neden
                      </th>
                      <th className="px-4 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">
                        Detay
                      </th>
                      <th className="px-4 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">
                        Admin Notu
                      </th>
                      <th className="px-4 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">
                        Durum
                      </th>
                      <th className="px-4 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">
                        Tarih
                      </th>
                      <th className="px-4 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">
                        İşlem
                      </th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-border">
                    {list.map((appeal) => (
                      <tr key={appeal.appeal_id} className="hover:bg-black/[0.02]">
                        {/* Başvuran — maskeli, ham UUID gösterilmez */}
                        <td className="px-4 py-3 font-mono text-xs text-muted">
                          {appeal.appellant_user_id}
                        </td>

                        {/* Kaynak tipi badge */}
                        <td className="px-4 py-3">
                          <span className="rounded-full bg-card border border-border px-2 py-0.5 text-[10px] font-[700] text-muted">
                            {SOURCE_TYPE_LABELS[appeal.source_type] ?? appeal.source_type}
                          </span>
                        </td>

                        {/* Neden */}
                        <td className="max-w-[200px] px-4 py-3 text-muted">
                          <p className="line-clamp-2 text-xs">
                            {appeal.reason ?? '—'}
                          </p>
                        </td>

                        {/* Detay */}
                        <td className="max-w-[200px] px-4 py-3 text-muted">
                          <p className="line-clamp-2 text-xs">
                            {appeal.details ?? '—'}
                          </p>
                        </td>

                        {/* Admin Notu */}
                        <td className="max-w-[160px] px-4 py-3 text-muted">
                          <p className="line-clamp-1 text-xs">
                            {appeal.decision_note ?? '—'}
                          </p>
                        </td>

                        {/* Durum badge */}
                        <td className="px-4 py-3">
                          <span
                            className={`rounded-full px-2 py-0.5 text-[10px] font-[800] ${
                              APPEAL_STATUS_STYLES[appeal.status as AppealStatus] ??
                              'bg-zinc-100 text-zinc-500'
                            }`}
                          >
                            {APPEAL_STATUS_LABELS[appeal.status as AppealStatus | 'all'] ??
                              appeal.status}
                          </span>
                        </td>

                        {/* Tarih */}
                        <td className="px-4 py-3 text-xs text-muted">
                          {new Date(appeal.created_at).toLocaleDateString('tr-TR')}
                        </td>

                        {/* İşlem — sadece pending satırlar için */}
                        <td className="px-4 py-3">
                          {appeal.status === 'pending' ? (
                            <form action={decideAppealAction} className="flex flex-col gap-1.5 min-w-[160px]">
                              <input type="hidden" name="appeal_id" value={appeal.appeal_id} />
                              <input type="hidden" name="status" value={status} />
                              <input
                                type="text"
                                name="note"
                                placeholder="Not (opsiyonel)"
                                className="rounded border border-border bg-card px-2 py-1 text-xs text-textStrong placeholder:text-muted focus:outline-none focus:ring-1 focus:ring-primary/50"
                              />
                              <div className="flex gap-1.5">
                                <button
                                  type="submit"
                                  name="decision"
                                  value="approved"
                                  className="flex-1 rounded-lg bg-green-50 px-2.5 py-1 text-[11px] font-[700] text-green-700 transition-colors hover:bg-green-100"
                                >
                                  Onayla
                                </button>
                                <button
                                  type="submit"
                                  name="decision"
                                  value="rejected"
                                  className="flex-1 rounded-lg bg-red-50 px-2.5 py-1 text-[11px] font-[700] text-red-700 transition-colors hover:bg-red-100"
                                >
                                  Reddet
                                </button>
                              </div>
                            </form>
                          ) : (
                            <span className="text-xs text-muted">
                              {appeal.decided_at
                                ? new Date(appeal.decided_at).toLocaleDateString('tr-TR')
                                : '—'}
                            </span>
                          )}
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>

              {/* Pagination */}
              {totalPages > 1 && (
                <div className="flex items-center justify-between border-t border-border px-5 py-3">
                  <span className="text-xs text-muted">
                    Sayfa {pageNum} / {totalPages}
                  </span>
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

function FlagIcon() {
  return (
    <svg
      width="20"
      height="20"
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth="2"
      strokeLinecap="round"
      strokeLinejoin="round"
    >
      <path d="M4 15s1-1 4-1 5 2 8 2 4-1 4-1V3s-1 1-4 1-5-2-8-2-4 1-4 1z" />
      <line x1="4" y1="22" x2="4" y2="15" />
    </svg>
  );
}
