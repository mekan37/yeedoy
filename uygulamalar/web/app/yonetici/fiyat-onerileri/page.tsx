import type { Metadata } from 'next';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { PanelSayfaBasligi } from '@/src/ui/yerlesim/panel-page-header';
import { PanelIcerikYuzeyi, PanelBolumKarti } from '@/src/ui/yerlesim/panel-section-card';
import { PanelEmptyState } from '@/src/ui/bilesenler/panel-bos-durum';

export const metadata: Metadata = {
  title: 'Fiyat Önerileri | Yonetici Paneli',
  robots: { index: false, follow: false },
};

type Props = { searchParams: Promise<{ status?: string; page?: string }> };
const PAGE_SIZE = 50;

const STATUS_MAP: Record<string, { label: string; className: string }> = {
  pending: { label: 'Bekliyor', className: 'bg-amber-50 text-amber-700' },
  approved: { label: 'Onaylandı', className: 'bg-green-50 text-green-700' },
  rejected: { label: 'Reddedildi', className: 'bg-red-50 text-red-700' },
};

function formatPrice(cents: number, currency: string) {
  return new Intl.NumberFormat('tr-TR', { style: 'currency', currency: currency || 'TRY', minimumFractionDigits: 2 }).format(cents / 100);
}

export default async function AdminPriceSuggestionsPage({ searchParams }: Props) {
  const { status = 'pending', page = '1' } = await searchParams;
  const pageNum = Math.max(1, parseInt(page, 10));
  const offset = (pageNum - 1) * PAGE_SIZE;

  const supabase = await createSupabaseServerClient();

  let query = (supabase as any)
    .from('menu_item_price_suggestions')
    .select(
      'id, suggested_price_cents, currency, note, status, created_at, quality_confidence, onsite_verified, ' +
      'menu_items(id, name, price_cents, currency), ' +
      'businesses(name)',
      { count: 'exact' },
    )
    .order('created_at', { ascending: false })
    .range(offset, offset + PAGE_SIZE - 1);

  if (status !== 'all') {
    query = query.eq('status', status);
  }

  const { data: suggestions, count } = await query;
  const list = (suggestions ?? []) as any[];
  const totalPages = Math.ceil((count ?? 0) / PAGE_SIZE);

  return (
    <div className="flex flex-col">
      <PanelSayfaBasligi
        eyebrow="Admin"
        title="Fiyat Önerileri"
        description={count != null ? `${count.toLocaleString('tr-TR')} öneri` : ''}
      />
      <PanelIcerikYuzeyi className="pt-6">
        <form method="get" className="mb-4 flex gap-2">
          {[
            { value: 'pending', label: 'Bekleyen' },
            { value: 'approved', label: 'Onaylandı' },
            { value: 'rejected', label: 'Reddedildi' },
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
          <PanelEmptyState icon={<TagIcon />} title="Öneri bulunamadı" />
        ) : (
          <PanelBolumKarti noPadding>
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b border-border text-left">
                  <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">Ürün</th>
                  <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">İşletme</th>
                  <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">Mevcut</th>
                  <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">Önerilen</th>
                  <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">Güven</th>
                  <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">Durum</th>
                  <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">Tarih</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-border">
                {list.map((s: any) => {
                  const statusInfo = STATUS_MAP[s.status] ?? STATUS_MAP['pending'];
                  return (
                    <tr key={s.id} className="hover:bg-black/[0.01]">
                      <td className="px-5 py-3">
                        <p className="font-[700] text-textStrong">{s.menu_items?.name ?? '—'}</p>
                        {s.note && <p className="text-xs text-muted italic">{s.note}</p>}
                      </td>
                      <td className="px-5 py-3 text-muted">{s.businesses?.name ?? '—'}</td>
                      <td className="px-5 py-3 text-muted">
                        {s.menu_items ? formatPrice(s.menu_items.price_cents, s.menu_items.currency) : '—'}
                      </td>
                      <td className="px-5 py-3 font-[800] text-textStrong">
                        {formatPrice(s.suggested_price_cents, s.currency)}
                      </td>
                      <td className="px-5 py-3">
                        <div className="flex items-center gap-1">
                          <div className="h-1.5 w-16 overflow-hidden rounded-full bg-border">
                            <div
                              className="h-full bg-primary"
                              style={{ width: `${Math.round(Number(s.quality_confidence ?? 0) * 100)}%` }}
                            />
                          </div>
                          <span className="text-xs text-muted">
                            {Math.round(Number(s.quality_confidence ?? 0) * 100)}%
                          </span>
                        </div>
                        {s.onsite_verified && (
                          <span className="mt-0.5 block text-[10px] font-[700] text-green-600">Yerinde Doğrulandı</span>
                        )}
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

function TagIcon() {
  return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M20.59 13.41l-7.17 7.17a2 2 0 0 1-2.83 0L2 12V2h10l8.59 8.59a2 2 0 0 1 0 2.82z" /><line x1="7" y1="7" x2="7.01" y2="7" /></svg>;
}

