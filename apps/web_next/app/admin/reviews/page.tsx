import type { Metadata } from 'next';
import { createSupabaseServerClient } from '@/src/lib/supabaseServer';
import { PanelPageHeader } from '@/src/ui/layout/panel-page-header';
import { PanelContentSurface, PanelSectionCard } from '@/src/ui/layout/panel-section-card';
import { PanelEmptyState } from '@/src/ui/components/panel-empty-state';

export const metadata: Metadata = {
  title: 'Yorumlar | Admin Panel',
  robots: { index: false, follow: false },
};

type Props = { searchParams: Promise<{ visible?: string; page?: string } > };
const PAGE_SIZE = 40;

export default async function AdminReviewsPage({ searchParams }: Props) {
  const { visible = 'all', page = '1' } = await searchParams;
  const pageNum = Math.max(1, parseInt(page, 10));
  const offset = (pageNum - 1) * PAGE_SIZE;

  const supabase = await createSupabaseServerClient();

  let query = (supabase as any)
    .from('business_reviews')
    .select(
      'id, rating, content, is_visible, created_at, ' +
      'businesses(name), user_profiles!created_by(display_name)',
      { count: 'exact' },
    )
    .order('created_at', { ascending: false })
    .range(offset, offset + PAGE_SIZE - 1);

  if (visible === 'visible') query = query.eq('is_visible', true);
  if (visible === 'hidden') query = query.eq('is_visible', false);

  const { data: reviews, count } = await query;
  const list = (reviews ?? []) as any[];
  const totalPages = Math.ceil((count ?? 0) / PAGE_SIZE);

  return (
    <div className="flex flex-col">
      <PanelPageHeader
        eyebrow="Admin"
        title="Yorumlar"
        description={count != null ? `${count.toLocaleString('tr-TR')} yorum` : ''}
      />
      <PanelContentSurface className="pt-6">
        <form method="get" className="mb-4 flex gap-2">
          {[
            { value: 'all', label: 'Tümü' },
            { value: 'visible', label: 'Görünür' },
            { value: 'hidden', label: 'Gizli' },
          ].map(({ value, label }) => (
            <button key={value} type="submit" name="visible" value={value}
              className={`rounded-lg px-3 py-1.5 text-xs font-[700] transition-colors ${
                visible === value ? 'bg-primary text-white' : 'border border-border bg-card text-muted hover:text-textStrong'
              }`}>
              {label}
            </button>
          ))}
        </form>

        {list.length === 0 ? (
          <PanelEmptyState icon={<StarIcon />} title="Yorum bulunamadı" />
        ) : (
          <PanelSectionCard noPadding>
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b border-border text-left">
                  <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">Yorum</th>
                  <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">İşletme</th>
                  <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">Kullanıcı</th>
                  <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">Puan</th>
                  <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">Durum</th>
                  <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">Tarih</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-border">
                {list.map((r: any) => (
                  <tr key={r.id} className="hover:bg-black/[0.01]">
                    <td className="max-w-xs px-5 py-3">
                      <p className="line-clamp-2 text-xs text-muted">{r.content ?? '—'}</p>
                    </td>
                    <td className="px-5 py-3 font-[700] text-textStrong">{r.businesses?.name ?? '—'}</td>
                    <td className="px-5 py-3 text-muted">{r.user_profiles?.display_name ?? '—'}</td>
                    <td className="px-5 py-3">
                      <span className="font-[800] text-amber-500">{'★'.repeat(r.rating)}{'☆'.repeat(5 - r.rating)}</span>
                    </td>
                    <td className="px-5 py-3">
                      <span className={`rounded-full px-2 py-0.5 text-[10px] font-[800] ${
                        r.is_visible ? 'bg-green-50 text-green-700' : 'bg-zinc-100 text-zinc-500'
                      }`}>
                        {r.is_visible ? 'Görünür' : 'Gizli'}
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
                  {pageNum > 1 && <a href={`?visible=${visible}&page=${pageNum - 1}`} className="rounded-lg border border-border px-3 py-1 text-xs font-[700] text-textStrong hover:bg-black/[0.02]">← Önceki</a>}
                  {pageNum < totalPages && <a href={`?visible=${visible}&page=${pageNum + 1}`} className="rounded-lg border border-border px-3 py-1 text-xs font-[700] text-textStrong hover:bg-black/[0.02]">Sonraki →</a>}
                </div>
              </div>
            )}
          </PanelSectionCard>
        )}
      </PanelContentSurface>
    </div>
  );
}

function StarIcon() {
  return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2" /></svg>;
}
