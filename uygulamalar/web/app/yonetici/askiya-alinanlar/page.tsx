import type { Metadata } from 'next';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { PanelSayfaBasligi } from '@/src/ui/yerlesim/panel-page-header';
import { PanelIcerikYuzeyi, PanelBolumKarti } from '@/src/ui/yerlesim/panel-section-card';
import { PanelEmptyState } from '@/src/ui/bilesenler/panel-bos-durum';
import { MetricCard } from '@/src/ui/bilesenler/olcum-karti';

export const metadata: Metadata = {
  title: 'Askıya Alma Yönetimi | Yonetici Paneli',
  robots: { index: false, follow: false },
};

type Props = { searchParams: Promise<{ status?: string; page?: string }> };
const PAGE_SIZE = 40;

function formatPrice(cents: number, currency: string) {
  return new Intl.NumberFormat('tr-TR', { style: 'currency', currency: currency || 'TRY', minimumFractionDigits: 2 }).format(cents / 100);
}

export default async function AdminSuspendedPage({ searchParams }: Props) {
  const { status = 'active', page = '1' } = await searchParams;
  const pageNum = Math.max(1, parseInt(page, 10));
  const offset = (pageNum - 1) * PAGE_SIZE;

  const supabase = await createSupabaseServerClient();

  const [mealsRes, claimsCountRes, expiredCountRes] = await Promise.all([
    (supabase as any)
      .from('suspended_meals')
      .select(
        'id, business_id, amount_cents, currency, message, status, created_at, expires_at, ' +
        'businesses(name, city)',
        { count: 'exact' },
      )
      .eq('status', status === 'all' ? undefined : status)
      .order('created_at', { ascending: false })
      .range(offset, offset + PAGE_SIZE - 1),
    (supabase as any)
      .from('suspended_meal_claims')
      .select('id', { count: 'exact', head: true })
      .eq('status', 'pending'),
    (supabase as any)
      .from('suspended_meals')
      .select('id', { count: 'exact', head: true })
      .eq('status', 'active')
      .lt('expires_at', new Date().toISOString()),
  ]);

  const { data: meals, count: totalCount } = mealsRes;
  const list = (meals ?? []) as any[];
  const totalPages = Math.ceil((totalCount ?? 0) / PAGE_SIZE);

  return (
    <div className="flex flex-col">
      <PanelSayfaBasligi
        eyebrow="Admin"
        title="Askıya Alma Yönetimi"
        description="Askıya alınan yemek bağışları ve talepler"
      />
      <PanelIcerikYuzeyi className="pt-6">
        <div className="flex flex-col gap-6">
          <div className="grid grid-cols-1 gap-4 sm:grid-cols-3">
            <MetricCard title="Bekleyen Talep" value={claimsCountRes.count ?? 0} icon={<GiftIcon />} />
            <MetricCard title="Süresi Dolmuş" value={expiredCountRes.count ?? 0} icon={<ClockIcon />} />
            <MetricCard title="Bu Sayfada" value={list.length} icon={<ListIcon />} />
          </div>

          {/* Status filter */}
          <form method="get" className="flex gap-2">
            {[
              { value: 'active', label: 'Aktif' },
              { value: 'expired', label: 'Süresi Dolmuş' },
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
            <PanelEmptyState icon={<GiftIcon />} title="Askıya alınan yemek yok" />
          ) : (
            <PanelBolumKarti noPadding>
              <table className="w-full text-sm">
                <thead>
                  <tr className="border-b border-border text-left">
                    <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">İşletme</th>
                    <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">Tutar</th>
                    <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">Durum</th>
                    <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">Son Kullanma</th>
                    <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">Tarih</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-border">
                  {list.map((m: any) => {
                    const isExpired = new Date(m.expires_at) < new Date();
                    return (
                      <tr key={m.id}>
                        <td className="px-5 py-3">
                          <p className="font-[700] text-textStrong">{m.businesses?.name ?? '—'}</p>
                          <p className="text-xs text-muted">{m.businesses?.city}</p>
                        </td>
                        <td className="px-5 py-3 font-[800] text-textStrong">
                          {formatPrice(m.amount_cents, m.currency)}
                        </td>
                        <td className="px-5 py-3">
                          <span className={`rounded-full px-2 py-0.5 text-[10px] font-[800] ${
                            m.status === 'active' && !isExpired ? 'bg-green-50 text-green-700' :
                            isExpired ? 'bg-red-50 text-red-700' : 'bg-zinc-100 text-zinc-500'
                          }`}>
                            {isExpired ? 'Süresi Doldu' : m.status === 'active' ? 'Aktif' : m.status}
                          </span>
                        </td>
                        <td className="px-5 py-3 text-xs text-muted">
                          {new Date(m.expires_at).toLocaleDateString('tr-TR')}
                        </td>
                        <td className="px-5 py-3 text-xs text-muted">
                          {new Date(m.created_at).toLocaleDateString('tr-TR')}
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
        </div>
      </PanelIcerikYuzeyi>
    </div>
  );
}

function GiftIcon() {
  return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><polyline points="20 12 20 22 4 22 4 12" /><rect x="2" y="7" width="20" height="5" /><line x1="12" y1="22" x2="12" y2="7" /><path d="M12 7H7.5a2.5 2.5 0 0 1 0-5C11 2 12 7 12 7z" /><path d="M12 7h4.5a2.5 2.5 0 0 0 0-5C13 2 12 7 12 7z" /></svg>;
}
function ClockIcon() {
  return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><circle cx="12" cy="12" r="10" /><polyline points="12 6 12 12 16 14" /></svg>;
}
function ListIcon() {
  return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><line x1="8" y1="6" x2="21" y2="6" /><line x1="8" y1="12" x2="21" y2="12" /><line x1="8" y1="18" x2="21" y2="18" /><line x1="3" y1="6" x2="3.01" y2="6" /><line x1="3" y1="12" x2="3.01" y2="12" /><line x1="3" y1="18" x2="3.01" y2="18" /></svg>;
}

