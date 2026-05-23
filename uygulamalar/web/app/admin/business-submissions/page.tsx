import type { Metadata } from 'next';
import { createSupabaseServerClient } from '@/src/lib/supabaseServer';
import { PanelPageHeader } from '@/src/ui/layout/panel-page-header';
import { PanelContentSurface, PanelSectionCard } from '@/src/ui/layout/panel-section-card';
import { PanelEmptyState } from '@/src/ui/components/panel-empty-state';

export const metadata: Metadata = {
  title: 'İşletme Talepleri | Admin Panel',
  robots: { index: false, follow: false },
};

type Props = { searchParams: Promise<{ status?: string; page?: string }> };
const PAGE_SIZE = 40;

const STATUS_MAP: Record<string, { label: string; className: string }> = {
  new: { label: 'Yeni', className: 'bg-amber-50 text-amber-700' },
  approved: { label: 'Onaylandı', className: 'bg-green-50 text-green-700' },
  rejected: { label: 'Reddedildi', className: 'bg-red-50 text-red-700' },
};

export default async function AdminBusinessSubmissionsPage({ searchParams }: Props) {
  const { status = 'new', page = '1' } = await searchParams;
  const pageNum = Math.max(1, parseInt(page, 10));
  const offset = (pageNum - 1) * PAGE_SIZE;

  const supabase = await createSupabaseServerClient();

  let query = (supabase as any)
    .from('business_submissions')
    .select(
      'id, name, city, district, category, address, phone, website, status, admin_note, created_at, submitted_by, ' +
      'user_profiles!submitted_by(display_name, email)',
      { count: 'exact' },
    )
    .order('created_at', { ascending: false })
    .range(offset, offset + PAGE_SIZE - 1);

  if (status !== 'all') {
    query = query.eq('status', status);
  }

  const { data: submissions, count } = await query;
  const list = (submissions ?? []) as any[];
  const totalPages = Math.ceil((count ?? 0) / PAGE_SIZE);

  return (
    <div className="flex flex-col">
      <PanelPageHeader
        eyebrow="Admin"
        title="İşletme Talepleri"
        description={count != null ? `${count.toLocaleString('tr-TR')} talep` : ''}
      />
      <PanelContentSurface className="pt-6">
        {/* Status filter */}
        <form method="get" className="mb-4 flex gap-2">
          {[
            { value: 'new', label: 'Yeni' },
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
                status === value ? 'bg-primary text-white' : 'border border-border bg-card text-muted hover:text-textStrong'
              }`}
            >
              {label}
            </button>
          ))}
        </form>

        {list.length === 0 ? (
          <PanelEmptyState icon={<BuildingIcon />} title="Talep bulunamadı" />
        ) : (
          <PanelSectionCard noPadding>
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b border-border text-left">
                  <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">İşletme</th>
                  <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">Kategori</th>
                  <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">Şehir</th>
                  <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">Başvuran</th>
                  <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">Durum</th>
                  <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">Tarih</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-border">
                {list.map((s: any) => {
                  const statusInfo = STATUS_MAP[s.status] ?? STATUS_MAP['new'];
                  return (
                    <tr key={s.id} className="hover:bg-black/[0.01]">
                      <td className="px-5 py-3">
                        <p className="font-[700] text-textStrong">{s.name}</p>
                        <p className="text-xs text-muted">{s.address}</p>
                        {s.admin_note && (
                          <p className="mt-1 text-xs italic text-muted">Admin: {s.admin_note}</p>
                        )}
                      </td>
                      <td className="px-5 py-3 text-muted">{s.category}</td>
                      <td className="px-5 py-3 text-muted">{s.city}, {s.district}</td>
                      <td className="px-5 py-3">
                        <p className="text-xs font-[700] text-textStrong">{s.user_profiles?.display_name ?? '—'}</p>
                        <p className="text-xs text-muted">{s.user_profiles?.email ?? s.submitted_by.slice(0, 8)}</p>
                      </td>
                      <td className="px-5 py-3">
                        <span className={`rounded-full px-2 py-0.5 text-[10px] font-[800] ${statusInfo.className}`}>
                          {statusInfo.label}
                        </span>
                      </td>
                      <td className="px-5 py-3 text-xs text-muted">
                        {new Date(s.created_at).toLocaleDateString('tr-TR')}
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

function BuildingIcon() {
  return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><rect x="4" y="2" width="16" height="20" rx="2" ry="2" /><path d="M9 22V12h6v10" /></svg>;
}
