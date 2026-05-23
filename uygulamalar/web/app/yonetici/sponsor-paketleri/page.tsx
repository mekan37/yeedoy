import type { Metadata } from 'next';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { PanelSayfaBasligi } from '@/src/ui/yerlesim/panel-page-header';
import { PanelIcerikYuzeyi, PanelBolumKarti } from '@/src/ui/yerlesim/panel-section-card';
import { PanelEmptyState } from '@/src/ui/bilesenler/panel-bos-durum';

export const metadata: Metadata = {
  title: 'Sponsorluk Paketleri | Yonetici Paneli',
  robots: { index: false, follow: false },
};

export default async function AdminSponsorshipPackagesPage() {
  const supabase = await createSupabaseServerClient();

  let list: any[] = [];
  let tableExists = true;

  try {
    const { data, error } = await (supabase as any)
      .from('sponsorship_packages')
      .select('id, name, surface, duration_days, price_display, price_cents, currency_code, inventory_limit, is_active, created_at')
      .order('price_cents', { ascending: true });

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
      <PanelSayfaBasligi
        eyebrow="Admin"
        title="Sponsorluk Paketleri"
        description="Mevcut sponsorluk paketlerini görüntüle ve yönet"
      />
      <PanelIcerikYuzeyi className="pt-6">
        {!tableExists ? (
          <PanelBolumKarti>
            <PanelEmptyState
              icon={<PackageIcon />}
              title="Paket modülü yakında"
              description="Sponsorluk paket yönetimi altyapısı henüz hazır değil."
            />
          </PanelBolumKarti>
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
                  {pkg.price_display
                    ? pkg.price_display
                    : pkg.price_cents != null
                      ? new Intl.NumberFormat('tr-TR', {
                          style: 'currency',
                          currency: pkg.currency_code ?? 'TRY',
                          minimumFractionDigits: 0,
                        }).format(pkg.price_cents / 100)
                      : '—'}
                </p>
                <div className="flex flex-wrap gap-1.5 mb-3">
                  {pkg.duration_days && (
                    <span className="rounded-md bg-border/30 px-2 py-0.5 text-[10px] font-[700] text-muted">
                      {pkg.duration_days} gün
                    </span>
                  )}
                  {pkg.surface && (
                    <span className="rounded-md bg-primary/8 px-2 py-0.5 text-[10px] font-[800] text-primary">
                      {pkg.surface}
                    </span>
                  )}
                  {pkg.inventory_limit != null && (
                    <span className="rounded-md bg-border/30 px-2 py-0.5 text-[10px] font-[700] text-muted">
                      Maks {pkg.inventory_limit} slot
                    </span>
                  )}
                </div>
              </div>
            ))}
          </div>
        )}
      </PanelIcerikYuzeyi>
    </div>
  );
}

function PackageIcon() { return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><line x1="16.5" y1="9.4" x2="7.5" y2="4.21" /><path d="M21 16V8a2 2 0 0 0-1-1.73l-7-4a2 2 0 0 0-2 0l-7 4A2 2 0 0 0 3 8v8a2 2 0 0 0 1 1.73l7 4a2 2 0 0 0 2 0l7-4A2 2 0 0 0 21 16z" /><polyline points="3.27 6.96 12 12.01 20.73 6.96" /><line x1="12" y1="22.08" x2="12" y2="12" /></svg>; }

