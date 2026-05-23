import type { Metadata } from 'next';
import { createSupabaseServerClient } from '@/src/lib/supabaseServer';
import { PanelPageHeader } from '@/src/ui/layout/panel-page-header';
import { PanelContentSurface, PanelSectionCard } from '@/src/ui/layout/panel-section-card';
import { PanelEmptyState } from '@/src/ui/components/panel-empty-state';

export const metadata: Metadata = {
  title: 'Masa Geri Bildirimleri | Admin Panel',
  robots: { index: false, follow: false },
};

function starLabel(rating: number | null): string {
  if (!rating) return '—';
  return '★'.repeat(Math.max(0, Math.min(5, rating))) + '☆'.repeat(5 - Math.max(0, Math.min(5, rating)));
}

function ratingColor(rating: number | null): string {
  if (!rating) return 'text-muted';
  if (rating >= 4) return 'text-emerald-600';
  if (rating >= 3) return 'text-amber-600';
  return 'text-red-600';
}

export default async function AdminTableFeedbackPage() {
  const supabase = await createSupabaseServerClient();

  let list: any[] = [];
  let count: number | null = null;
  let tableExists = true;

  try {
    const { data, count: total, error } = await (supabase as any)
      .from('table_feedback')
      .select('id, table_id, business_id, message, rating, created_at', { count: 'exact' })
      .order('created_at', { ascending: false })
      .range(0, 49);

    if (error && (error.code === '42P01' || error.message?.includes('does not exist'))) {
      tableExists = false;
    } else if (error) {
      tableExists = false;
    } else {
      list = (data ?? []) as any[];
      count = total ?? 0;
    }
  } catch {
    tableExists = false;
  }

  return (
    <div className="flex flex-col">
      <PanelPageHeader
        eyebrow="Admin"
        title="Masa Geri Bildirimleri"
        description={
          tableExists && count != null
            ? `${count.toLocaleString('tr-TR')} geri bildirim`
            : 'Masa bazlı müşteri geri bildirimleri'
        }
      />
      <PanelContentSurface className="pt-6">
        {!tableExists ? (
          <PanelSectionCard>
            <PanelEmptyState
              icon={<MessageIcon />}
              title="Tablo bulunamadı"
              description="table_feedback tablosu henüz oluşturulmamış. Masa geri bildirimi altyapısı yapılandırıldıktan sonra bu sayfa otomatik olarak aktif hale gelecek."
            />
          </PanelSectionCard>
        ) : list.length === 0 ? (
          <PanelSectionCard>
            <PanelEmptyState
              icon={<MessageIcon />}
              title="Geri bildirim bulunamadı"
              description="Henüz hiç masa geri bildirimi gönderilmemiş."
            />
          </PanelSectionCard>
        ) : (
          <PanelSectionCard noPadding>
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b border-border text-left">
                  <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">Tarih</th>
                  <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">İşletme ID</th>
                  <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">Masa No</th>
                  <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">Mesaj</th>
                  <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">Puan</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-border">
                {list.map((entry: any) => (
                  <tr key={entry.id} className="hover:bg-black/[0.01]">
                    <td className="px-5 py-3 text-xs text-muted whitespace-nowrap">
                      {entry.created_at
                        ? new Date(entry.created_at).toLocaleString('tr-TR', {
                            day: '2-digit',
                            month: '2-digit',
                            year: 'numeric',
                            hour: '2-digit',
                            minute: '2-digit',
                          })
                        : '—'}
                    </td>
                    <td className="px-5 py-3 font-mono text-xs text-muted">
                      {entry.business_id
                        ? String(entry.business_id).length > 16
                          ? String(entry.business_id).slice(0, 12) + '…'
                          : entry.business_id
                        : '—'}
                    </td>
                    <td className="px-5 py-3 text-xs text-textStrong">
                      {entry.table_id ?? '—'}
                    </td>
                    <td className="px-5 py-3 text-xs text-textStrong max-w-[280px]">
                      {entry.message
                        ? String(entry.message).slice(0, 60) + (String(entry.message).length > 60 ? '…' : '')
                        : <span className="text-muted italic">Mesaj yok</span>}
                    </td>
                    <td className={`px-5 py-3 text-xs font-[700] whitespace-nowrap ${ratingColor(entry.rating)}`}>
                      {starLabel(entry.rating)}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </PanelSectionCard>
        )}
      </PanelContentSurface>
    </div>
  );
}

function MessageIcon() {
  return (
    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z" />
    </svg>
  );
}
