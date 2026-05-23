import type { Metadata } from 'next';
import { createSupabaseServerClient } from '@/src/lib/supabaseServer';
import { PanelPageHeader } from '@/src/ui/layout/panel-page-header';
import { PanelContentSurface, PanelSectionCard } from '@/src/ui/layout/panel-section-card';
import { PanelEmptyState } from '@/src/ui/components/panel-empty-state';

export const metadata: Metadata = {
  title: 'Sponsorluk Adayları | Admin Panel',
  robots: { index: false, follow: false },
};

type Props = { searchParams: Promise<{ status?: string }> };

const STATUS_MAP: Record<string, { label: string; className: string }> = {
  new:        { label: 'Yeni',         className: 'bg-blue-50 text-blue-700' },
  contacted:  { label: 'İletişime Geçildi', className: 'bg-amber-50 text-amber-700' },
  negotiating:{ label: 'Müzakerede',   className: 'bg-purple-50 text-purple-700' },
  closed_won: { label: 'Kazanıldı',    className: 'bg-green-50 text-green-700' },
  closed_lost:{ label: 'Kaybedildi',   className: 'bg-zinc-100 text-zinc-500' },
};

export default async function AdminSponsorshipLeadsPage({ searchParams }: Props) {
  const { status = 'all' } = await searchParams;
  const supabase = await createSupabaseServerClient();

  let list: any[] = [];
  let count: number | null = null;
  let tableExists = true;

  try {
    let query = (supabase as any)
      .from('sponsorship_leads')
      .select('id, company_name, contact_name, contact_email, status, budget, notes, created_at', { count: 'exact' })
      .order('created_at', { ascending: false });

    if (status !== 'all') query = query.eq('status', status);

    const { data, count: total, error } = await query;
    if (error && (error.code === '42P01' || error.message?.includes('does not exist'))) {
      tableExists = false;
    } else {
      list = data ?? [];
      count = total ?? 0;
    }
  } catch {
    tableExists = false;
  }

  return (
    <div className="flex flex-col">
      <PanelPageHeader
        eyebrow="Admin"
        title="Sponsorluk Adayları"
        description={tableExists && count != null ? `${count.toLocaleString('tr-TR')} aday` : 'Potansiyel sponsor adaylarını yönet'}
      />
      <PanelContentSurface className="pt-6">
        {!tableExists ? (
          <PanelSectionCard>
            <PanelEmptyState
              icon={<UserPlusIcon />}
              title="Aday modülü yakında"
              description="Sponsorluk aday yönetimi altyapısı henüz hazır değil."
            />
          </PanelSectionCard>
        ) : (
          <>
            <form method="get" className="mb-4 flex flex-wrap gap-2">
              {[
                { value: 'all',         label: 'Tümü' },
                { value: 'new',         label: 'Yeni' },
                { value: 'contacted',   label: 'İletişime Geçildi' },
                { value: 'negotiating', label: 'Müzakerede' },
                { value: 'closed_won',  label: 'Kazanıldı' },
                { value: 'closed_lost', label: 'Kaybedildi' },
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
                icon={<UserPlusIcon />}
                title="Aday bulunamadı"
                description="Seçilen filtre için kayıt yok."
              />
            ) : (
              <PanelSectionCard noPadding>
                <table className="w-full text-sm">
                  <thead>
                    <tr className="border-b border-border text-left">
                      <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">Şirket</th>
                      <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">İletişim</th>
                      <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">Bütçe</th>
                      <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">Durum</th>
                      <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">Tarih</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-border">
                    {list.map((lead: any) => {
                      const statusInfo = STATUS_MAP[lead.status] ?? STATUS_MAP['new'];
                      return (
                        <tr key={lead.id} className="hover:bg-black/[0.01]">
                          <td className="px-5 py-3 font-[700] text-textStrong">{lead.company_name ?? '—'}</td>
                          <td className="px-5 py-3 text-muted">
                            <p>{lead.contact_name ?? '—'}</p>
                            <p className="text-xs">{lead.contact_email ?? ''}</p>
                          </td>
                          <td className="px-5 py-3 font-[700] text-textStrong">
                            {lead.budget != null
                              ? new Intl.NumberFormat('tr-TR', { style: 'currency', currency: 'TRY' }).format(lead.budget)
                              : '—'}
                          </td>
                          <td className="px-5 py-3">
                            <span className={`rounded-full px-2 py-0.5 text-[10px] font-[800] ${statusInfo.className}`}>
                              {statusInfo.label}
                            </span>
                          </td>
                          <td className="px-5 py-3 text-xs text-muted">
                            {new Date(lead.created_at).toLocaleDateString('tr-TR')}
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

function UserPlusIcon() { return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M16 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2" /><circle cx="8.5" cy="7" r="4" /><line x1="20" y1="8" x2="20" y2="14" /><line x1="23" y1="11" x2="17" y2="11" /></svg>; }
