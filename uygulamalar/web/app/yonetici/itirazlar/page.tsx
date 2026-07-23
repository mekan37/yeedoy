import type { Metadata } from 'next';
import Link from 'next/link';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { PanelSayfaBasligi } from '@/src/ui/yerlesim/panel-page-header';
import { PanelIcerikYuzeyi, PanelBolumKarti } from '@/src/ui/yerlesim/panel-section-card';
import { PanelEmptyState } from '@/src/ui/bilesenler/panel-bos-durum';
import { reviewAppeal } from './itiraz-islemleri';

export const metadata: Metadata = {
  title: 'İtirazlar | Yonetici Paneli',
  robots: { index: false, follow: false },
};

type Props = { searchParams: Promise<{ status?: string; page?: string }> };
const PAGE_SIZE = 40;

const STATUS_STYLES: Record<string, string> = {
  pending:  'bg-amber-50 text-amber-700',
  approved: 'bg-green-50 text-green-700',
  rejected: 'bg-red-50 text-red-700',
};
const STATUS_LABELS: Record<string, string> = {
  pending: 'Bekliyor', approved: 'Onaylandı', rejected: 'Reddedildi',
};
const SOURCE_LABELS: Record<string, string> = {
  review: 'Yorum', business: 'İşletme', menu_item: 'Menü Öğesi', user: 'Kullanıcı',
};

export default async function AdminAppealsPage({ searchParams }: Props) {
  const { status = 'pending', page = '1' } = await searchParams;
  const pageNum = Math.max(1, parseInt(page, 10));
  const offset  = (pageNum - 1) * PAGE_SIZE;

  const supabase = await createSupabaseServerClient();

  let baseQ = (supabase as any)
    .from('moderation_appeals')
    .select(`
      id, source_type, source_id, reason, details, status,
      decision_note, decided_at, created_at,
      appellant:appellant_user_id ( id, email, display_name:user_profiles(display_name) )
    `, { count: 'exact' })
    .order('created_at', { ascending: false })
    .range(offset, offset + PAGE_SIZE - 1);

  if (status !== 'all') baseQ = baseQ.eq('status', status);

  const { data, count, error } = await baseQ;
  const list = (data ?? []) as any[];
  const totalPages = Math.ceil((count ?? 0) / PAGE_SIZE);

  return (
    <div className="flex flex-col">
      <PanelSayfaBasligi
        eyebrow="Yönetici"
        title="İtirazlar"
        description={`${(count ?? 0).toLocaleString('tr-TR')} kayıt`}
      />
      <PanelIcerikYuzeyi className="pt-6">
        {/* Durum filtresi */}
        <form method="get" className="mb-4 flex flex-wrap gap-2">
          {[
            { v: 'pending', l: 'Bekliyor' },
            { v: 'approved', l: 'Onaylandı' },
            { v: 'rejected', l: 'Reddedildi' },
            { v: 'all', l: 'Tümü' },
          ].map(({ v, l }) => (
            <button key={v} type="submit" name="status" value={v}
              className={`rounded-lg px-3 py-1.5 text-xs font-[700] transition-colors ${
                status === v ? 'bg-primary text-white' : 'border border-border bg-card text-muted hover:text-textStrong'
              }`}>
              {l}
            </button>
          ))}
        </form>

        {error ? (
          <PanelEmptyState icon={<FlagIcon />} title="Veri yüklenemedi" description={error.message} />
        ) : list.length === 0 ? (
          <PanelEmptyState icon={<FlagIcon />} title="İtiraz yok" description="Seçilen filtre için kayıt bulunamadı." />
        ) : (
          <PanelBolumKarti noPadding>
            <div className="overflow-x-auto">
              <table className="w-full text-sm">
                <thead>
                  <tr className="border-b border-border text-left">
                    {['Başvuran', 'Kaynak', 'Neden', 'Detay', 'Durum', 'Tarih', 'İşlem'].map((h) => (
                      <th key={h} className="px-4 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted whitespace-nowrap">{h}</th>
                    ))}
                  </tr>
                </thead>
                <tbody className="divide-y divide-border">
                  {list.map((a: any) => {
                    const name = a.appellant?.display_name?.[0]?.display_name ?? a.appellant?.email ?? a.appellant_user_id?.slice(0, 8);
                    return (
                      <tr key={a.id} className="hover:bg-black/[0.02]">
                        <td className="px-4 py-3 text-xs text-textStrong font-[700] whitespace-nowrap">{name ?? '—'}</td>
                        <td className="px-4 py-3">
                          <span className="rounded-full bg-border/60 px-2 py-0.5 text-[10px] font-[800] text-muted">
                            {SOURCE_LABELS[a.source_type] ?? a.source_type}
                          </span>
                        </td>
                        <td className="max-w-[200px] px-4 py-3 text-xs text-muted">
                          <p className="line-clamp-2">{a.reason ?? '—'}</p>
                        </td>
                        <td className="max-w-[180px] px-4 py-3 text-xs text-muted">
                          <p className="line-clamp-2">{a.details ?? '—'}</p>
                        </td>
                        <td className="px-4 py-3">
                          <span className={`rounded-full px-2 py-0.5 text-[10px] font-[800] ${STATUS_STYLES[a.status] ?? 'bg-zinc-100 text-zinc-600'}`}>
                            {STATUS_LABELS[a.status] ?? a.status}
                          </span>
                        </td>
                        <td className="px-4 py-3 text-xs text-muted whitespace-nowrap">
                          {new Date(a.created_at).toLocaleDateString('tr-TR')}
                        </td>
                        <td className="px-4 py-3">
                          {a.status === 'pending' && (
                            <div className="flex gap-1.5">
                              <form action={reviewAppeal}>
                                <input type="hidden" name="id" value={a.id} />
                                <input type="hidden" name="decision" value="approved" />
                                <input type="hidden" name="status" value={status} />
                                <button type="submit" className="rounded-lg bg-green-50 px-2.5 py-1 text-[10px] font-[800] text-green-700 hover:bg-green-100">
                                  Onayla
                                </button>
                              </form>
                              <form action={reviewAppeal}>
                                <input type="hidden" name="id" value={a.id} />
                                <input type="hidden" name="decision" value="rejected" />
                                <input type="hidden" name="status" value={status} />
                                <button type="submit" className="rounded-lg bg-red-50 px-2.5 py-1 text-[10px] font-[800] text-red-700 hover:bg-red-100">
                                  Reddet
                                </button>
                              </form>
                            </div>
                          )}
                        </td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            </div>

            {totalPages > 1 && (
              <div className="flex items-center justify-between border-t border-border px-5 py-3">
                <span className="text-xs text-muted">Sayfa {pageNum} / {totalPages}</span>
                <div className="flex gap-2">
                  {pageNum > 1 && (
                    <Link href={`?status=${status}&page=${pageNum - 1}`} className="rounded-lg border border-border px-3 py-1 text-xs font-[700] hover:bg-black/[0.02]">← Önceki</Link>
                  )}
                  {pageNum < totalPages && (
                    <Link href={`?status=${status}&page=${pageNum + 1}`} className="rounded-lg border border-border px-3 py-1 text-xs font-[700] hover:bg-black/[0.02]">Sonraki →</Link>
                  )}
                </div>
              </div>
            )}
          </PanelBolumKarti>
        )}
      </PanelIcerikYuzeyi>
    </div>
  );
}

function FlagIcon() {
  return (
    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M4 15s1-1 4-1 5 2 8 2 4-1 4-1V3s-1 1-4 1-5-2-8-2-4 1-4 1z" />
      <line x1="4" y1="22" x2="4" y2="15" />
    </svg>
  );
}
