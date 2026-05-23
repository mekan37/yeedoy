import type { Metadata } from 'next';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { PanelSayfaBasligi } from '@/src/ui/yerlesim/panel-page-header';
import { PanelIcerikYuzeyi, PanelBolumKarti } from '@/src/ui/yerlesim/panel-section-card';
import { PanelEmptyState } from '@/src/ui/bilesenler/panel-bos-durum';
import { markLeadContacted } from './sponsor-aday-islemleri';

export const metadata: Metadata = {
  title: 'Sponsor Adayları | Yonetici Paneli',
  robots: { index: false, follow: false },
};

type Props = { searchParams: Promise<{ status?: string }> };

export default async function AdminSponsorLeadsPage({ searchParams }: Props) {
  const { status = 'new' } = await searchParams;
  const supabase = await createSupabaseServerClient();

  let q = (supabase as any)
    .from('sponsorship_leads')
    .select(`
      id, phone, message, preferred_surface, status, created_at,
      business:business_id ( name, city, category )
    `, { count: 'exact' })
    .order('created_at', { ascending: false });

  if (status !== 'all') q = q.eq('status', status);

  const { data, count, error } = await q;
  const list = (data ?? []) as any[];

  return (
    <div className="flex flex-col">
      <PanelSayfaBasligi
        eyebrow="Admin"
        title="Sponsor Adayları"
        description={`${(count ?? 0).toLocaleString('tr-TR')} başvuru`}
      />
      <PanelIcerikYuzeyi className="pt-6">
        <form method="get" className="mb-4 flex gap-2">
          {[{ v: 'new', l: 'Yeni' }, { v: 'contacted', l: 'İletişim Kuruldu' }, { v: 'all', l: 'Tümü' }].map(({ v, l }) => (
            <button key={v} type="submit" name="status" value={v}
              className={`rounded-lg px-3 py-1.5 text-xs font-[700] transition-colors ${
                status === v ? 'bg-primary text-white' : 'border border-border bg-card text-muted hover:text-textStrong'
              }`}>
              {l}
            </button>
          ))}
        </form>

        {error ? (
          <PanelEmptyState icon={<UserPlusIcon />} title="Veri yüklenemedi" />
        ) : list.length === 0 ? (
          <PanelEmptyState icon={<UserPlusIcon />} title="Aday bulunamadı" description="Seçili filtre için kayıt yok." />
        ) : (
          <PanelBolumKarti noPadding>
            <div className="divide-y divide-border">
              {list.map((l: any) => (
                <div key={l.id} className="flex items-start gap-4 px-5 py-4">
                  <div className="flex-1 min-w-0">
                    <div className="flex items-center gap-2">
                      <p className="font-[800] text-textStrong truncate">{l.business?.name ?? '—'}</p>
                      <span className="shrink-0 rounded-full bg-border/40 px-2 py-0.5 text-[10px] font-[700] text-muted">
                        {l.business?.category ?? ''}
                      </span>
                    </div>
                    <p className="mt-0.5 text-xs text-muted">
                      {l.business?.city && <span className="mr-2">{l.business.city}</span>}
                      {l.phone && <span className="font-[700]">{l.phone}</span>}
                      {l.preferred_surface && (
                        <span className="ml-2 rounded bg-primary/8 px-1.5 py-0.5 text-[10px] font-[800] text-primary">
                          {l.preferred_surface}
                        </span>
                      )}
                    </p>
                    {l.message && <p className="mt-1.5 text-sm text-muted">{l.message}</p>}
                    <p className="mt-1 text-[11px] text-muted">
                      {new Date(l.created_at).toLocaleDateString('tr-TR', { day: 'numeric', month: 'long', year: 'numeric' })}
                    </p>
                  </div>
                  <div className="flex shrink-0 items-center gap-2">
                    <span className={`rounded-full px-2.5 py-1 text-[10px] font-[800] ${
                      l.status === 'contacted' ? 'bg-green-50 text-green-700' : 'bg-amber-50 text-amber-700'
                    }`}>
                      {l.status === 'contacted' ? 'İletişim Kuruldu' : 'Yeni'}
                    </span>
                    {l.status === 'new' && (
                      <form action={markLeadContacted}>
                        <input type="hidden" name="id" value={l.id} />
                        <input type="hidden" name="currentStatus" value={status} />
                        <button type="submit"
                          className="rounded-lg border border-border px-3 py-1.5 text-xs font-[700] text-textStrong hover:bg-black/[0.04]">
                          İletişim Kuruldu →
                        </button>
                      </form>
                    )}
                  </div>
                </div>
              ))}
            </div>
          </PanelBolumKarti>
        )}
      </PanelIcerikYuzeyi>
    </div>
  );
}

function UserPlusIcon() {
  return (
    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2" />
      <circle cx="9" cy="7" r="4" />
      <line x1="19" y1="8" x2="19" y2="14" />
      <line x1="22" y1="11" x2="16" y2="11" />
    </svg>
  );
}
