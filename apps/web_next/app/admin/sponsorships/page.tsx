import type { Metadata } from 'next';
import { createSupabaseServerClient } from '@/src/lib/supabaseServer';
import { PanelPageHeader } from '@/src/ui/layout/panel-page-header';
import { PanelContentSurface, PanelSectionCard } from '@/src/ui/layout/panel-section-card';
import { PanelEmptyState } from '@/src/ui/components/panel-empty-state';

export const metadata: Metadata = {
  title: 'Sponsorluklar | Admin Panel',
  robots: { index: false, follow: false },
};

type Props = { searchParams: Promise<{ status?: string }> };

const STATUS_MAP: Record<string, { label: string; className: string }> = {
  active: { label: 'Aktif', className: 'bg-green-50 text-green-700' },
  pending: { label: 'Beklemede', className: 'bg-amber-50 text-amber-700' },
  expired: { label: 'Süresi Doldu', className: 'bg-zinc-100 text-zinc-500' },
  cancelled: { label: 'İptal', className: 'bg-red-50 text-red-700' },
};

export default async function AdminSponsorshipsPage({ searchParams }: Props) {
  const { status = 'all' } = await searchParams;

  const supabase = await createSupabaseServerClient();

  let list: any[] = [];
  let count: number | null = null;
  let tableExists = true;

  try {
    let query = (supabase as any)
      .from('sponsorships')
      .select('id, sponsor_name, package, amount, start_date, end_date, status, created_at', { count: 'exact' })
      .order('created_at', { ascending: false });

    if (status !== 'all') {
      query = query.eq('status', status);
    }

    const { data, count: total, error } = await query;

    if (error && (error.code === '42P01' || error.message?.includes('does not exist'))) {
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
        title="Sponsorluklar"
        description={tableExists && count != null ? `${count.toLocaleString('tr-TR')} sponsorluk` : 'Sponsorluk anlaşmalarını yönet'}
      />
      <PanelContentSurface className="pt-6">
        {!tableExists ? (
          <PanelSectionCard>
            <PanelEmptyState
              icon={<StarIcon />}
              title="Sponsorluk modülü yakında"
              description="Sponsorluk yönetimi altyapısı henüz hazır değil. Bu modül yakında aktif hale gelecek."
            />
          </PanelSectionCard>
        ) : (
          <>
            {/* Status filter */}
            <form method="get" className="mb-4 flex flex-wrap gap-2">
              {[
                { value: 'all', label: 'Tümü' },
                { value: 'active', label: 'Aktif' },
                { value: 'pending', label: 'Beklemede' },
                { value: 'expired', label: 'Süresi Doldu' },
                { value: 'cancelled', label: 'İptal' },
              ].map(({ value, label }) => (
                <button
                  key={value}
                  type="submit"
                  name="status"
                  value={value}
                  className={`rounded-lg px-3 py-1.5 text-xs font-[700] transition-colors ${
                    status === value
                      ? 'bg-primary text-white'
                      : 'bg-card border border-border text-muted hover:text-textStrong'
                  }`}
                >
                  {label}
                </button>
              ))}
            </form>

            {list.length === 0 ? (
              <PanelEmptyState
                icon={<StarIcon />}
                title="Sponsorluk bulunamadı"
                description="Seçilen filtre için kayıt yok."
              />
            ) : (
              <PanelSectionCard noPadding>
                <table className="w-full text-sm">
                  <thead>
                    <tr className="border-b border-border text-left">
                      <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">Sponsör</th>
                      <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">Paket</th>
                      <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">Tutar</th>
                      <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">Başlangıç</th>
                      <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">Bitiş</th>
                      <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">Durum</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-border">
                    {list.map((s: any) => {
                      const statusInfo = STATUS_MAP[s.status] ?? STATUS_MAP['pending'];
                      return (
                        <tr key={s.id} className="hover:bg-black/[0.01]">
                          <td className="px-5 py-3 font-[700] text-textStrong">{s.sponsor_name ?? '—'}</td>
                          <td className="px-5 py-3 text-muted capitalize">{s.package ?? '—'}</td>
                          <td className="px-5 py-3 font-[700] text-textStrong">
                            {s.amount != null
                              ? new Intl.NumberFormat('tr-TR', { style: 'currency', currency: 'TRY' }).format(s.amount)
                              : '—'}
                          </td>
                          <td className="px-5 py-3 text-xs text-muted">
                            {s.start_date ? new Date(s.start_date).toLocaleDateString('tr-TR') : '—'}
                          </td>
                          <td className="px-5 py-3 text-xs text-muted">
                            {s.end_date ? new Date(s.end_date).toLocaleDateString('tr-TR') : '—'}
                          </td>
                          <td className="px-5 py-3">
                            <span className={`rounded-full px-2 py-0.5 text-[10px] font-[800] ${statusInfo.className}`}>
                              {statusInfo.label}
                            </span>
                          </td>
                        </tr>
                      );
                    })}
                  </tbody>
                </table>
              </PanelSectionCard>
            )}
          </>
        )}
      </PanelContentSurface>
    </div>
  );
}

function StarIcon() {
  return (
    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2" />
    </svg>
  );
}
