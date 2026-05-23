import type { Metadata } from 'next';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { PanelSayfaBasligi } from '@/src/ui/yerlesim/panel-page-header';
import { PanelIcerikYuzeyi, PanelBolumKarti } from '@/src/ui/yerlesim/panel-section-card';
import { PanelEmptyState } from '@/src/ui/bilesenler/panel-bos-durum';

export const metadata: Metadata = {
  title: 'Sponsorluklar | Yonetici Paneli',
  robots: { index: false, follow: false },
};

type Props = { searchParams: Promise<{ status?: string }> };

const STATUS_STYLES: Record<string, string> = {
  active:    'bg-green-50 text-green-700',
  pending:   'bg-amber-50 text-amber-700',
  expired:   'bg-zinc-100 text-zinc-500',
  cancelled: 'bg-red-50 text-red-700',
  paused:    'bg-blue-50 text-blue-700',
};
const STATUS_LABELS: Record<string, string> = {
  active: 'Aktif', pending: 'Beklemede', expired: 'Süresi Doldu',
  cancelled: 'İptal', paused: 'Duraklatıldı',
};

export default async function AdminSponsorshipsPage({ searchParams }: Props) {
  const { status = 'all' } = await searchParams;
  const supabase = await createSupabaseServerClient();

  // Sponsorluklar + işletme adı + paket adı
  let q = (supabase as any)
    .from('sponsorships')
    .select(`
      id, surface, status, starts_at, ends_at,
      daily_cap, total_cap, source, created_at,
      business:business_id ( name, city ),
      package:package_id ( name )
    `, { count: 'exact' })
    .order('created_at', { ascending: false });

  if (status !== 'all') q = q.eq('status', status);

  const { data, count, error } = await q;
  const list = (data ?? []) as any[];

  // Özet istatistikler
  const { data: statsData } = await (supabase as any)
    .from('sponsorships')
    .select('status');

  const stats = (statsData ?? []).reduce((acc: Record<string, number>, s: any) => {
    acc[s.status] = (acc[s.status] ?? 0) + 1;
    return acc;
  }, {});

  return (
    <div className="flex flex-col">
      <PanelSayfaBasligi
        eyebrow="Admin"
        title="Sponsorluklar"
        description={`${(count ?? 0).toLocaleString('tr-TR')} sponsorluk anlaşması`}
      />
      <PanelIcerikYuzeyi className="pt-6">
        {/* KPI özet */}
        <div className="mb-5 grid grid-cols-2 gap-3 sm:grid-cols-4">
          {[
            { label: 'Aktif', value: stats['active'] ?? 0, cls: 'text-green-700 bg-green-50' },
            { label: 'Bekleyen', value: stats['pending'] ?? 0, cls: 'text-amber-700 bg-amber-50' },
            { label: 'Süresi Dolmuş', value: stats['expired'] ?? 0, cls: 'text-zinc-500 bg-zinc-100' },
            { label: 'Toplam', value: Object.values(stats).reduce((a: number, b) => a + (b as number), 0), cls: 'text-primary bg-primary/8' },
          ].map(({ label, value, cls }) => (
            <div key={label} className="rounded-xl border border-border bg-card p-4">
              <p className="text-xs font-[800] text-muted">{label}</p>
              <p className={`mt-1 text-2xl font-[900] ${cls} rounded-lg px-2 py-0.5 inline-block`}>{value}</p>
            </div>
          ))}
        </div>

        {/* Filtre */}
        <form method="get" className="mb-4 flex flex-wrap gap-2">
          {[
            { v: 'all', l: 'Tümü' },
            { v: 'active', l: 'Aktif' },
            { v: 'pending', l: 'Beklemede' },
            { v: 'expired', l: 'Süresi Doldu' },
            { v: 'cancelled', l: 'İptal' },
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
          <PanelEmptyState icon={<StarIcon />} title="Veri yüklenemedi" description={error.message} />
        ) : list.length === 0 ? (
          <PanelEmptyState icon={<StarIcon />} title="Sponsorluk bulunamadı" description="Seçili filtre için kayıt yok." />
        ) : (
          <PanelBolumKarti noPadding>
            <div className="overflow-x-auto">
              <table className="w-full text-sm">
                <thead>
                  <tr className="border-b border-border text-left">
                    {['İşletme', 'Paket', 'Yüzey', 'Başlangıç', 'Bitiş', 'Günlük Kap', 'Durum'].map((h) => (
                      <th key={h} className="px-4 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted whitespace-nowrap">{h}</th>
                    ))}
                  </tr>
                </thead>
                <tbody className="divide-y divide-border">
                  {list.map((s: any) => (
                    <tr key={s.id} className="hover:bg-black/[0.01]">
                      <td className="px-4 py-3">
                        <p className="font-[700] text-textStrong">{s.business?.name ?? '—'}</p>
                        <p className="text-xs text-muted">{s.business?.city ?? ''}</p>
                      </td>
                      <td className="px-4 py-3 text-sm text-muted">{s.package?.name ?? '—'}</td>
                      <td className="px-4 py-3">
                        <span className="rounded-full bg-border/40 px-2 py-0.5 text-[10px] font-[700] text-muted capitalize">
                          {s.surface ?? '—'}
                        </span>
                      </td>
                      <td className="px-4 py-3 text-xs text-muted whitespace-nowrap">
                        {s.starts_at ? new Date(s.starts_at).toLocaleDateString('tr-TR') : '—'}
                      </td>
                      <td className="px-4 py-3 text-xs text-muted whitespace-nowrap">
                        {s.ends_at ? new Date(s.ends_at).toLocaleDateString('tr-TR') : '—'}
                      </td>
                      <td className="px-4 py-3 text-xs text-muted">{s.daily_cap ?? '∞'}</td>
                      <td className="px-4 py-3">
                        <span className={`rounded-full px-2 py-0.5 text-[10px] font-[800] ${STATUS_STYLES[s.status] ?? 'bg-zinc-100 text-zinc-600'}`}>
                          {STATUS_LABELS[s.status] ?? s.status}
                        </span>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </PanelBolumKarti>
        )}

        {/* Adaylar bölümü */}
        <SponsorLeads supabase={supabase} />
      </PanelIcerikYuzeyi>
    </div>
  );
}

async function SponsorLeads({ supabase }: { supabase: any }) {
  const { data: leads } = await supabase
    .from('sponsorship_leads')
    .select('id, phone, message, preferred_surface, status, created_at, business:business_id(name)')
    .order('created_at', { ascending: false })
    .limit(20);

  if (!leads?.length) return null;

  return (
    <PanelBolumKarti title="Sponsorluk Adayları" description="İlgisini bildiren işletmeler" className="mt-5">
      <div className="divide-y divide-border">
        {leads.map((l: any) => (
          <div key={l.id} className="flex items-start gap-3 py-3">
            <div className="flex-1">
              <p className="font-[700] text-textStrong">{l.business?.name ?? '—'}</p>
              <p className="mt-0.5 text-xs text-muted">
                {l.preferred_surface && <span className="mr-2 rounded bg-border/40 px-1.5 py-0.5 font-[700]">{l.preferred_surface}</span>}
                {l.phone}
              </p>
              {l.message && <p className="mt-1 text-xs text-muted line-clamp-2">{l.message}</p>}
            </div>
            <span className={`shrink-0 rounded-full px-2 py-0.5 text-[10px] font-[800] ${
              l.status === 'contacted' ? 'bg-green-50 text-green-700' : 'bg-amber-50 text-amber-700'
            }`}>
              {l.status === 'contacted' ? 'İletişime Geçildi' : 'Yeni'}
            </span>
          </div>
        ))}
      </div>
    </PanelBolumKarti>
  );
}

function StarIcon() {
  return (
    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2" />
    </svg>
  );
}
