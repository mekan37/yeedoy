import type { Metadata } from 'next';
import { createSupabaseServerClient } from '@/src/lib/supabaseServer';
import { PanelPageHeader } from '@/src/ui/layout/panel-page-header';
import { PanelContentSurface, PanelSectionCard } from '@/src/ui/layout/panel-section-card';
import { PanelEmptyState } from '@/src/ui/components/panel-empty-state';

export const metadata: Metadata = {
  title: 'Sponsorluk Paketleri | Admin Panel',
  robots: { index: false, follow: false },
};

export default async function AdminSponsorshipPackagesPage() {
  const supabase = await createSupabaseServerClient();

  let list: any[] = [];
  let tableExists = true;

  try {
    const { data, error } = await (supabase as any)
      .from('sponsorship_packages')
      .select('id, name, price, duration_days, features, is_active, created_at')
      .order('price', { ascending: true });

    if (error && (error.code === '42P01' || error.message?.includes('does not exist'))) {
      tableExists = false;
    } else {
      list = data ?? [];
    }
  } catch {
    tableExists = false;
  }

  return (
    <div className="flex flex-col">
      <PanelPageHeader
        eyebrow="Admin"
        title="Sponsorluk Paketleri"
        description="Mevcut sponsorluk paketlerini görüntüle ve yönet"
      />
      <PanelContentSurface className="pt-6">
        {!tableExists ? (
          <PanelSectionCard>
            <PanelEmptyState
              icon={<PackageIcon />}
              title="Paket modülü yakında"
              description="Sponsorluk paket yönetimi altyapısı henüz hazır değil."
            />
          </PanelSectionCard>
        ) : list.length === 0 ? (
          <PanelEmptyState
            icon={<PackageIcon />}
            title="Paket bulunamadı"
            description="Henüz tanımlanmış sponsorluk paketi yok."
          />
        ) : (
          <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3">
            {list.map((pkg: any) => (
              <div key={pkg.id} className="rounded-2xl border border-border bg-card p-5">
                <div className="flex items-start justify-between gap-2 mb-3">
                  <h3 className="font-[800] text-textStrong">{pkg.name}</h3>
                  <span className={`shrink-0 rounded-full px-2 py-0.5 text-[10px] font-[800] ${
                    pkg.is_active ? 'bg-green-50 text-green-700' : 'bg-zinc-100 text-zinc-500'
                  }`}>
                    {pkg.is_active ? 'Aktif' : 'Pasif'}
                  </span>
                </div>
                <p className="text-2xl font-[900] text-primary mb-1">
                  {pkg.price != null
                    ? new Intl.NumberFormat('tr-TR', { style: 'currency', currency: 'TRY' }).format(pkg.price)
                    : '—'}
                </p>
                {pkg.duration_days && (
                  <p className="text-xs text-muted mb-3">{pkg.duration_days} gün</p>
                )}
                {Array.isArray(pkg.features) && pkg.features.length > 0 && (
                  <ul className="flex flex-col gap-1">
                    {pkg.features.map((f: string, i: number) => (
                      <li key={i} className="flex items-center gap-1.5 text-xs text-muted">
                        <CheckIcon />
                        {f}
                      </li>
                    ))}
                  </ul>
                )}
              </div>
            ))}
          </div>
        )}
      </PanelContentSurface>
    </div>
  );
}

function PackageIcon() { return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><line x1="16.5" y1="9.4" x2="7.5" y2="4.21" /><path d="M21 16V8a2 2 0 0 0-1-1.73l-7-4a2 2 0 0 0-2 0l-7 4A2 2 0 0 0 3 8v8a2 2 0 0 0 1 1.73l7 4a2 2 0 0 0 2 0l7-4A2 2 0 0 0 21 16z" /><polyline points="3.27 6.96 12 12.01 20.73 6.96" /><line x1="12" y1="22.08" x2="12" y2="12" /></svg>; }
function CheckIcon() { return <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round"><polyline points="20 6 9 17 4 12" /></svg>; }
