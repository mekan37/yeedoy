import type { Metadata } from 'next';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { PanelSayfaBasligi } from '@/src/ui/yerlesim/panel-page-header';
import { PanelIcerikYuzeyi, PanelBolumKarti } from '@/src/ui/yerlesim/panel-section-card';

export const metadata: Metadata = {
  title: 'B2B Dışa Aktarma | Yonetici Paneli',
  robots: { index: false, follow: false },
};

export default async function AdminB2bExportsPage() {
  const supabase = await createSupabaseServerClient();

  // Özet sayımlar
  const [{ count: bizCount }, { count: menuCount }] = await Promise.all([
    (supabase as any).from('businesses').select('id', { count: 'exact', head: true }).eq('is_active', true),
    (supabase as any).from('menu_items').select('id', { count: 'exact', head: true }).eq('is_available', true),
  ]);

  const EXPORT_ITEMS = [
    {
      id: 'businesses',
      title: 'İşletme Listesi',
      description: 'Tüm aktif işletmeleri CSV olarak indir.',
      count: `${(bizCount ?? 0).toLocaleString('tr-TR')} işletme`,
      icon: <BuildingIcon />,
    },
    {
      id: 'menus',
      title: 'Menü Öğeleri',
      description: 'Aktif menü öğelerini ve fiyatları dışa aktar.',
      count: `${(menuCount ?? 0).toLocaleString('tr-TR')} öğe`,
      icon: <MenuIcon />,
    },
    {
      id: 'analytics',
      title: 'Analitik (Son 30 Gün)',
      description: 'Kullanıcı aktivitesi ve sayfa görüntülenme verisi.',
      count: 'Son 30 gün',
      icon: <ChartIcon />,
    },
  ] as const;

  return (
    <div className="flex flex-col">
      <PanelSayfaBasligi
        eyebrow="Admin"
        title="B2B Dışa Aktarma"
        description="CSV formatında veri dışa aktarma araçları"
      />
      <PanelIcerikYuzeyi className="pt-6">
        <div className="grid gap-4 sm:grid-cols-3">
          {EXPORT_ITEMS.map((item) => (
            <PanelBolumKarti key={item.id} title={item.title} description={item.description}>
              <div className="flex flex-col gap-4">
                <div className="flex items-center justify-between">
                  <div className="flex h-12 w-12 items-center justify-center rounded-xl border border-border bg-primary/5 text-primary">
                    {item.icon}
                  </div>
                  <span className="text-sm font-[800] text-muted">{item.count}</span>
                </div>
                <a
                  href={`/sunucu/b2b-export/${item.id}`}
                  download
                  className="flex items-center justify-center gap-2 rounded-xl bg-primary px-4 py-2.5 text-sm font-[800] text-white transition-opacity hover:opacity-90"
                >
                  <DownloadIcon />
                  CSV İndir
                </a>
              </div>
            </PanelBolumKarti>
          ))}
        </div>

        <PanelBolumKarti title="Kullanım Notları" className="mt-5">
          <ul className="space-y-2 text-sm text-muted">
            <li className="flex items-start gap-2">
              <span className="mt-0.5 text-primary">•</span>
              İşletme listesi: id, name, category, city, district, address, phone, lat, lng, source, created_at
            </li>
            <li className="flex items-start gap-2">
              <span className="mt-0.5 text-primary">•</span>
              Menü öğeleri: id, name, price, currency, business_id, created_at (max 50.000 satır)
            </li>
            <li className="flex items-start gap-2">
              <span className="mt-0.5 text-primary">•</span>
              Analitik: event_name, business_id, created_at — son 30 gün, max 100.000 satır
            </li>
            <li className="flex items-start gap-2">
              <span className="mt-0.5 text-primary">•</span>
              Tüm indirmeler admin loguna kaydedilir.
            </li>
          </ul>
        </PanelBolumKarti>
      </PanelIcerikYuzeyi>
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
      <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z" />
      <polyline points="14 2 14 8 20 8" />
      <line x1="16" y1="13" x2="8" y2="13" />
      <line x1="16" y1="17" x2="8" y2="17" />
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
    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
      <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4" />
      <polyline points="7 10 12 15 17 10" />
      <line x1="12" y1="15" x2="12" y2="3" />
    </svg>
  );
}
