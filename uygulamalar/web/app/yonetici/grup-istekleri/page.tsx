import type { Metadata } from 'next';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { PanelSayfaBasligi } from '@/src/ui/yerlesim/panel-page-header';
import { PanelIcerikYuzeyi, PanelBolumKarti } from '@/src/ui/yerlesim/panel-section-card';
import { PanelEmptyState } from '@/src/ui/bilesenler/panel-bos-durum';

export const metadata: Metadata = {
  title: 'Grup İstekleri | Yonetici Paneli',
  robots: { index: false, follow: false },
};

type Props = { searchParams: Promise<{ status?: string; page?: string }> };
const PAGE_SIZE = 40;

const STATUS_MAP: Record<string, { label: string; className: string }> = {
  open: { label: 'Açık', className: 'bg-green-50 text-green-700' },
  closed: { label: 'Kapalı', className: 'bg-zinc-100 text-zinc-500' },
  awarded: { label: 'Tamamlandı', className: 'bg-blue-50 text-blue-700' },
  cancelled: { label: 'İptal', className: 'bg-red-50 text-red-700' },
};

function formatPrice(cents: number, currency: string) {
  return new Intl.NumberFormat('tr-TR', { style: 'currency', currency: currency || 'TRY', minimumFractionDigits: 0 }).format(cents / 100);
}

export default async function AdminGroupRequestsPage({ searchParams }: Props) {
  const { status = 'open', page = '1' } = await searchParams;
  const pageNum = Math.max(1, parseInt(page, 10));
  const offset = (pageNum - 1) * PAGE_SIZE;

  const supabase = await createSupabaseServerClient();

  let query = (supabase as any)
    .from('group_requests')
    .select(
      'id, city, districts, category, date_time, party_size, budget_total_cents, currency, notes, status, created_at, ' +
      'user_profiles!created_by(display_name)',
      { count: 'exact' },
    )
    .order('created_at', { ascending: false })
    .range(offset, offset + PAGE_SIZE - 1);

  if (status !== 'all') {
    query = query.eq('status', status);
  }

  const { data: requests, count } = await query;
  const list = (requests ?? []) as any[];
  const totalPages = Math.ceil((count ?? 0) / PAGE_SIZE);

  return (
    <div className="flex flex-col">
      <PanelSayfaBasligi
        eyebrow="Admin"
        title="Grup İstekleri"
        description={count != null ? `${count.toLocaleString('tr-TR')} istek` : ''}
      />
      <PanelIcerikYuzeyi className="pt-6">
        <form method="get" className="mb-4 flex gap-2">
          {[
            { value: 'open', label: 'Açık' },
            { value: 'closed', label: 'Kapalı' },
            { value: 'awarded', label: 'Tamamlandı' },
            { value: 'cancelled', label: 'İptal' },
            { value: 'all', label: 'Tümü' },
          ].map(({ value, label }) => (
            <button key={value} type="submit" name="status" value={value}
              className={`rounded-lg px-3 py-1.5 text-xs font-[700] transition-colors ${
                status === value ? 'bg-primary text-white' : 'border border-border bg-card text-muted hover:text-textStrong'
              }`}>
              {label}
            </button>
          ))}
        </form>

        {list.length === 0 ? (
          <PanelEmptyState icon={<UsersIcon />} title="İstek bulunamadı" />
        ) : (
          <PanelBolumKarti noPadding>
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b border-border text-left">
                  <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">İstek</th>
                  <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">Şehir</th>
                  <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">Tarih</th>
                  <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">Kişi</th>
                  <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">Bütçe</th>
                  <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">Durum</th>
                  <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">Oluşturan</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-border">
                {list.map((r: any) => {
                  const statusInfo = STATUS_MAP[r.status] ?? STATUS_MAP['open'];
                  return (
                    <tr key={r.id} className="hover:bg-black/[0.01]">
                      <td className="px-5 py-3">
                        <p className="font-[700] text-textStrong">{r.category ?? 'Genel'}</p>
                        {r.notes && <p className="line-clamp-1 text-xs text-muted italic">{r.notes}</p>}
                      </td>
                      <td className="px-5 py-3 text-muted">
                        {r.city}
                        {r.districts?.length > 0 ? ` · ${(r.districts as string[]).join(', ')}` : ''}
                      </td>
                      <td className="px-5 py-3 text-xs text-muted">
                        {new Date(r.date_time).toLocaleDateString('tr-TR', {
                          day: 'numeric', month: 'short', hour: '2-digit', minute: '2-digit',
                        })}
                      </td>
                      <td className="px-5 py-3 font-[700] text-textStrong">{r.party_size}</td>
                      <td className="px-5 py-3 font-[700] text-textStrong">
                        {formatPrice(r.budget_total_cents, r.currency)}
                      </td>
                      <td className="px-5 py-3">
                        <span className={`rounded-full px-2 py-0.5 text-[10px] font-[800] ${statusInfo.className}`}>
                          {statusInfo.label}
                        </span>
                      </td>
                      <td className="px-5 py-3 text-xs text-muted">
                        {r.user_profiles?.display_name ?? '—'}
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
                  {pageNum > 1 && <a href={`?status=${status}&page=${pageNum - 1}`} className="rounded-lg border border-border px-3 py-1 text-xs font-[700] text-textStrong hover:bg-black/[0.02]">← Önceki</a>}
                  {pageNum < totalPages && <a href={`?status=${status}&page=${pageNum + 1}`} className="rounded-lg border border-border px-3 py-1 text-xs font-[700] text-textStrong hover:bg-black/[0.02]">Sonraki →</a>}
                </div>
              </div>
            )}
          </PanelBolumKarti>
        )}
      </PanelIcerikYuzeyi>
    </div>
  );
}

function UsersIcon() {
  return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2" /><circle cx="9" cy="7" r="4" /><path d="M23 21v-2a4 4 0 0 0-3-3.87" /><path d="M16 3.13a4 4 0 0 1 0 7.75" /></svg>;
}

