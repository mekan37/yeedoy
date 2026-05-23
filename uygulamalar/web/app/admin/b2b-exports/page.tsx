import type { Metadata } from 'next';
import { PanelPageHeader } from '@/src/ui/layout/panel-page-header';
import { PanelContentSurface, PanelSectionCard } from '@/src/ui/layout/panel-section-card';

export const metadata: Metadata = {
  title: 'B2B Dışa Aktarma | Admin Panel',
  robots: { index: false, follow: false },
};

const EXPORT_ITEMS = [
  {
    id: 'businesses',
    title: 'İşletme Listesi',
    description: 'Tüm kayıtlı işletmeleri CSV formatında dışa aktar.',
    icon: <BuildingIcon />,
  },
  {
    id: 'menus',
    title: 'Menü Veritabanı',
    description: 'Menü ve menü öğeleri verilerini dışa aktar.',
    icon: <MenuIcon />,
  },
  {
    id: 'analytics',
    title: 'Kullanıcı Analitikleri',
    description: 'Kullanıcı aktivitesi ve analitik verilerini dışa aktar.',
    icon: <ChartIcon />,
  },
] as const;

export default async function AdminB2bExportsPage() {
  return (
    <div className="flex flex-col">
      <PanelPageHeader
        eyebrow="Admin"
        title="B2B Dışa Aktarma"
        description="Veri dışa aktarma araçları yakında kullanıma sunulacak."
      />
      <PanelContentSurface className="pt-6">
        <div className="grid gap-4 sm:grid-cols-3">
          {EXPORT_ITEMS.map((item) => (
            <PanelSectionCard key={item.id} title={item.title} description={item.description}>
              <div className="flex flex-col gap-4">
                <div className="flex h-12 w-12 items-center justify-center rounded-xl text-muted"
                  style={{ background: 'radial-gradient(circle at center, rgba(127,29,29,0.08), rgba(127,29,29,0.03))' }}>
                  {item.icon}
                </div>
                <div className="flex items-center justify-between">
                  <span className="inline-flex items-center gap-1.5 rounded-full bg-amber-50 px-2.5 py-1 text-[11px] font-[800] text-amber-700">
                    <span className="h-1.5 w-1.5 rounded-full bg-amber-400" />
                    Hazırlanıyor
                  </span>
                  <button
                    type="button"
                    disabled
                    className="flex items-center gap-1.5 rounded-lg border border-border bg-card px-3 py-1.5 text-xs font-[700] text-muted opacity-50 cursor-not-allowed"
                  >
                    <DownloadIcon />
                    CSV İndir
                  </button>
                </div>
              </div>
            </PanelSectionCard>
          ))}
        </div>

        <div className="mt-8 rounded-2xl border border-dashed border-border bg-card/60 px-6 py-10 text-center">
          <div className="mx-auto flex h-16 w-16 items-center justify-center rounded-full text-2xl text-muted"
            style={{ background: 'radial-gradient(circle at center, rgba(127,29,29,0.10), rgba(127,29,29,0.04))' }}>
            <ExportIcon />
          </div>
          <p className="mt-4 text-[17px] font-[900] text-textStrong">Veri dışa aktarma araçları yakında</p>
          <p className="mt-1 text-sm leading-relaxed text-muted">
            B2B entegrasyonları için CSV ve JSON dışa aktarma altyapısı geliştirme aşamasındadır.
          </p>
        </div>
      </PanelContentSurface>
    </div>
  );
}

function BuildingIcon() {
  return (
    <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <rect x="3" y="2" width="18" height="20" rx="2" />
      <path d="M9 22V12h6v10" />
      <path d="M8 6h.01M12 6h.01M16 6h.01M8 10h.01M12 10h.01M16 10h.01" />
    </svg>
  );
}

function MenuIcon() {
  return (
    <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M14.5 10c-.83 0-1.5-.67-1.5-1.5v-5c0-.83.67-1.5 1.5-1.5s1.5.67 1.5 1.5v5c0 .83-.67 1.5-1.5 1.5z" />
      <path d="M20.5 10H19V8.5c0-.83.67-1.5 1.5-1.5s1.5.67 1.5 1.5-.67 1.5-1.5 1.5z" />
      <path d="M9.5 14.5v-5c0-.83-.67-1.5-1.5-1.5S6.5 8.67 6.5 9.5v5" />
      <path d="M3.5 14.5v-5c0-.83.67-1.5 1.5-1.5s1.5.67 1.5 1.5v5" />
      <path d="M6.5 18h2" />
      <path d="M18 18H6.5" />
      <path d="M6.5 14.5h2" />
      <path d="M9.5 14.5H18" />
    </svg>
  );
}

function ChartIcon() {
  return (
    <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <line x1="18" y1="20" x2="18" y2="10" />
      <line x1="12" y1="20" x2="12" y2="4" />
      <line x1="6" y1="20" x2="6" y2="14" />
      <line x1="2" y1="20" x2="22" y2="20" />
    </svg>
  );
}

function DownloadIcon() {
  return (
    <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
      <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4" />
      <polyline points="7 10 12 15 17 10" />
      <line x1="12" y1="15" x2="12" y2="3" />
    </svg>
  );
}

function ExportIcon() {
  return (
    <svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round">
      <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4" />
      <polyline points="17 8 12 3 7 8" />
      <line x1="12" y1="3" x2="12" y2="15" />
    </svg>
  );
}
