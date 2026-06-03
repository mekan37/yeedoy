import type { Metadata } from 'next';
import { PanelSayfaBasligi } from '@/src/ui/yerlesim/panel-page-header';
import { PanelIcerikYuzeyi, PanelBolumKarti } from '@/src/ui/yerlesim/panel-section-card';
import { PanelEmptyState } from '@/src/ui/bilesenler/panel-bos-durum';
import { listAdminSponsorPackages } from '@/src/lib/veri/admin/sponsorluk';

export const metadata: Metadata = {
  title: 'Sponsorluk Paketleri | Yonetici Paneli',
  robots: { index: false, follow: false },
};

const SURFACE_LABELS: Record<string, string> = {
  discovery: 'Kesif',
  business_page: 'Isletme Sayfasi',
  stories: 'Hikayeler',
  verified: 'Dogrulanmis',
  premium: 'Premium',
};

export default async function AdminSponsorshipPackagesPage() {
  const list = await listAdminSponsorPackages();

  return (
    <div className="flex flex-col">
      <PanelSayfaBasligi
        eyebrow="Admin"
        title="Sponsorluk Paketleri"
        description="Mevcut sponsorluk paketlerini goruntuleyip yonetin"
      />
      <PanelIcerikYuzeyi className="pt-6">
        {list.length === 0 ? (
          <PanelEmptyState
            icon={<PackageIcon />}
            title="Paket bulunamadi"
            description="Henuz tanimlanmis sponsorluk paketi yok."
          />
        ) : (
          <>
            {/* Ozet satiri */}
            <div className="mb-5 flex flex-wrap gap-3 text-sm">
              <div className="rounded-xl border border-border bg-card px-4 py-3">
                <span className="font-[800] text-textStrong">{list.length}</span>
                <span className="ml-1 text-muted">toplam paket</span>
              </div>
              <div className="rounded-xl border border-border bg-card px-4 py-3">
                <span className="font-[800] text-green-700">{list.filter((p) => p.is_active).length}</span>
                <span className="ml-1 text-muted">aktif</span>
              </div>
              <div className="rounded-xl border border-border bg-card px-4 py-3">
                <span className="font-[800] text-zinc-500">{list.filter((p) => !p.is_active).length}</span>
                <span className="ml-1 text-muted">pasif</span>
              </div>
            </div>

            {/* Paket kartlari */}
            <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3">
              {list.map((pkg) => (
                <div key={pkg.id} className="rounded-2xl border border-border bg-card p-5">
                  <div className="flex items-start justify-between gap-2 mb-3">
                    <h3 className="font-[800] text-textStrong">{pkg.name}</h3>
                    <span
                      className={`shrink-0 rounded-full px-2 py-0.5 text-[10px] font-[800] ${
                        pkg.is_active ? 'bg-green-50 text-green-700' : 'bg-zinc-100 text-zinc-500'
                      }`}
                    >
                      {pkg.is_active ? 'Aktif' : 'Pasif'}
                    </span>
                  </div>

                  {/* Fiyat */}
                  <p className="text-2xl font-[900] text-primary mb-1">
                    {pkg.price_display
                      ? pkg.price_display
                      : pkg.price_cents > 0
                        ? new Intl.NumberFormat('tr-TR', {
                            style: 'currency',
                            currency: pkg.currency_code ?? 'TRY',
                            minimumFractionDigits: 0,
                          }).format(pkg.price_cents / 100)
                        : 'Ucretsiz'}
                  </p>

                  {/* Etiketler */}
                  <div className="flex flex-wrap gap-1.5 mb-4">
                    {pkg.duration_days > 0 && (
                      <span className="rounded-md bg-border/30 px-2 py-0.5 text-[10px] font-[700] text-muted">
                        {pkg.duration_days} gun
                      </span>
                    )}
                    {pkg.surface && (
                      <span className="rounded-md bg-primary/8 px-2 py-0.5 text-[10px] font-[800] text-primary">
                        {SURFACE_LABELS[pkg.surface] ?? pkg.surface}
                      </span>
                    )}
                    {pkg.inventory_limit > 0 && (
                      <span className="rounded-md bg-border/30 px-2 py-0.5 text-[10px] font-[700] text-muted">
                        Maks {pkg.inventory_limit} slot
                      </span>
                    )}
                  </div>

                  {/* Olusturulma tarihi */}
                  <p className="text-[11px] text-muted">
                    {new Date(pkg.created_at).toLocaleDateString('tr-TR', {
                      day: 'numeric',
                      month: 'long',
                      year: 'numeric',
                    })}
                  </p>
                </div>
              ))}
            </div>
          </>
        )}
      </PanelIcerikYuzeyi>
    </div>
  );
}

function PackageIcon() {
  return (
    <svg
      width="20"
      height="20"
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth="2"
      strokeLinecap="round"
      strokeLinejoin="round"
    >
      <line x1="16.5" y1="9.4" x2="7.5" y2="4.21" />
      <path d="M21 16V8a2 2 0 0 0-1-1.73l-7-4a2 2 0 0 0-2 0l-7 4A2 2 0 0 0 3 8v8a2 2 0 0 0 1 1.73l7 4a2 2 0 0 0 2 0l7-4A2 2 0 0 0 21 16z" />
      <polyline points="3.27 6.96 12 12.01 20.73 6.96" />
      <line x1="12" y1="22.08" x2="12" y2="12" />
    </svg>
  );
}
