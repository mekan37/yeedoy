import type { Metadata } from 'next';
import { PanelPageHeader } from '@/src/ui/layout/panel-page-header';
import { PanelContentSurface, PanelSectionCard } from '@/src/ui/layout/panel-section-card';
import { ExportDownloadButton } from './export-download-button';

export const metadata: Metadata = {
  title: 'B2B Dışa Aktarma | Admin Panel',
  robots: { index: false, follow: false },
};

// Sayfa sunucu bileşenidir; export indirme client bileşeninden tetiklenir.

interface ExportItem {
  id: 'inflation' | 'trends' | 'regional';
  title: string;
  description: string;
  detail: string;
  defaultDays: number;
  columns: string;
  icon: React.ReactNode;
}

const EXPORT_ITEMS: ExportItem[] = [
  {
    id: 'inflation',
    title: 'Menü Fiyat Enflasyonu',
    description: 'Seçilen dönemde menü öğelerinde gözlemlenen fiyat değişimlerini dışa aktar.',
    detail: 'İşletme veya kullanıcı verisi içermez. Şehir/ilçe + ürün adı + fiyat değişim yüzdesi.',
    defaultDays: 90,
    columns: 'city, district, menu_item_name, first_price_cents, last_price_cents, inflation_pct',
    icon: <TrendIcon />,
  },
  {
    id: 'trends',
    title: 'Anonim Kullanım Trendleri',
    description: 'Günlük etkinlik sayılarını şehir/ilçe ve etkinlik tipine göre dışa aktar.',
    detail: 'Tamamen anonimleştirilmiştir. Bireysel kullanıcıya atfedilemez.',
    defaultDays: 30,
    columns: 'day, city, district, event_name, event_count',
    icon: <ChartIcon />,
  },
  {
    id: 'regional',
    title: 'Bölgesel Fiyat Endeksi',
    description: 'Şehir/ilçe bazında ortalama ve medyan menü fiyatlarını dışa aktar.',
    detail: 'Aggregate veri — işletme veya kullanıcı kimliği içermez.',
    defaultDays: 90,
    columns: 'city, district, avg_price_cents, median_price_cents, item_count, change_pct',
    icon: <MapIcon />,
  },
];

export default function AdminB2bExportsPage() {
  return (
    <div className="flex flex-col">
      <PanelPageHeader
        eyebrow="Admin"
        title="B2B Dışa Aktarma"
        description="Aggregate ve anonimleştirilmiş pazar verilerini CSV olarak dışa aktar. PII içermez."
      />
      <PanelContentSurface className="pt-6">
        {/* PII açıklaması */}
        <div className="mb-6 flex items-start gap-3 rounded-xl border border-blue-100 bg-blue-50/60 px-4 py-3">
          <InfoIcon />
          <p className="text-xs leading-relaxed text-blue-800">
            <span className="font-[800]">Veri gizliliği notu:</span> Tüm exportlar yalnızca aggregate veya
            anonimleştirilmiş verileri içerir. Bireysel kullanıcı, işletme sahibi veya kişisel bilgi
            (PII) bu raporlara dahil edilmemektedir.
          </p>
        </div>

        {/* Export kartları */}
        <div className="grid gap-4 sm:grid-cols-1 lg:grid-cols-3">
          {EXPORT_ITEMS.map((item) => (
            <PanelSectionCard key={item.id} title={item.title} description={item.description}>
              <div className="flex flex-col gap-4">
                {/* İkon */}
                <div
                  className="flex h-12 w-12 items-center justify-center rounded-xl text-muted"
                  style={{
                    background:
                      'radial-gradient(circle at center, rgba(127,29,29,0.08), rgba(127,29,29,0.03))',
                  }}
                >
                  {item.icon}
                </div>

                {/* PII notu */}
                <p className="text-[11px] leading-relaxed text-muted">{item.detail}</p>

                {/* Sütun listesi */}
                <div className="rounded-lg bg-black/[0.03] px-3 py-2">
                  <p className="text-[10px] font-[700] uppercase tracking-wide text-muted">Sütunlar</p>
                  <p className="mt-0.5 font-mono text-[10px] text-muted">{item.columns}</p>
                </div>

                {/* Durum badge + download buton */}
                <div className="flex items-center justify-between gap-2">
                  <span className="inline-flex items-center gap-1.5 rounded-full bg-green-50 px-2.5 py-1 text-[11px] font-[800] text-green-700">
                    <span className="h-1.5 w-1.5 rounded-full bg-green-400" />
                    Aktif
                  </span>
                  <ExportDownloadButton
                    exportType={item.id}
                    days={item.defaultDays}
                    label={`CSV İndir (${item.defaultDays}g)`}
                  />
                </div>
              </div>
            </PanelSectionCard>
          ))}
        </div>

        {/* Gelişmiş filtreler bölümü */}
        <div className="mt-6">
          <PanelSectionCard title="Özel Tarih Aralığı" description="Farklı gün aralıklarıyla export alın">
            <div className="grid gap-6 sm:grid-cols-3">
              {EXPORT_ITEMS.map((item) => (
                <div key={`adv-${item.id}`} className="space-y-3">
                  <p className="text-[13px] font-[800] text-textStrong">{item.title}</p>
                  <div className="flex flex-wrap gap-2">
                    {[7, 30, 90, 180, 365].map((days) => (
                      <ExportDownloadButton
                        key={days}
                        exportType={item.id}
                        days={days}
                        label={`${days}g`}
                      />
                    ))}
                  </div>
                </div>
              ))}
            </div>
          </PanelSectionCard>
        </div>
      </PanelContentSurface>
    </div>
  );
}

function TrendIcon() {
  return (
    <svg
      width="22"
      height="22"
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth="2"
      strokeLinecap="round"
      strokeLinejoin="round"
      aria-hidden="true"
    >
      <polyline points="22 7 13.5 15.5 8.5 10.5 2 17" />
      <polyline points="16 7 22 7 22 13" />
    </svg>
  );
}

function ChartIcon() {
  return (
    <svg
      width="22"
      height="22"
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth="2"
      strokeLinecap="round"
      strokeLinejoin="round"
      aria-hidden="true"
    >
      <line x1="18" y1="20" x2="18" y2="10" />
      <line x1="12" y1="20" x2="12" y2="4" />
      <line x1="6" y1="20" x2="6" y2="14" />
      <line x1="2" y1="20" x2="22" y2="20" />
    </svg>
  );
}

function MapIcon() {
  return (
    <svg
      width="22"
      height="22"
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth="2"
      strokeLinecap="round"
      strokeLinejoin="round"
      aria-hidden="true"
    >
      <polygon points="3 6 9 3 15 6 21 3 21 18 15 21 9 18 3 21" />
      <line x1="9" y1="3" x2="9" y2="18" />
      <line x1="15" y1="6" x2="15" y2="21" />
    </svg>
  );
}

function InfoIcon() {
  return (
    <svg
      width="16"
      height="16"
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth="2"
      strokeLinecap="round"
      strokeLinejoin="round"
      className="mt-0.5 shrink-0 text-blue-500"
      aria-hidden="true"
    >
      <circle cx="12" cy="12" r="10" />
      <line x1="12" y1="16" x2="12" y2="12" />
      <line x1="12" y1="8" x2="12.01" y2="8" />
    </svg>
  );
}
