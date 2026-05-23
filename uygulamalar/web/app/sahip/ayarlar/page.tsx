import type { Metadata } from 'next';
import Link from 'next/link';
import { PanelSayfaBasligi } from '@/src/ui/yerlesim/panel-page-header';
import { PanelIcerikYuzeyi } from '@/src/ui/yerlesim/panel-section-card';

export const metadata: Metadata = {
  title: 'Ayarlar | Sahip Paneli',
  robots: { index: false, follow: false },
};

const SETTINGS_ITEMS = [
  { href: '/sahip/ayarlar/saatler', label: 'Çalışma Saatleri', description: 'Günlük açılış/kapanış saatlerini ayarlayın', disabled: false },
  { href: '/sahip/ayarlar/alan-adi', label: 'Özel Domain', description: 'İşletmenize özel alan adı bağlayın', disabled: true },
];

export default function OwnerSettingsPage() {
  return (
    <div className="flex flex-col">
      <PanelSayfaBasligi eyebrow="Owner" title="Ayarlar" description="İşletme yapılandırma ve tercihler" />
      <PanelIcerikYuzeyi className="pt-6">
        <div className="flex flex-col gap-3 max-w-lg">
          {SETTINGS_ITEMS.map((item) =>
            item.disabled ? (
              <div key={item.href} className="flex items-center justify-between rounded-2xl border border-border bg-card px-6 py-5 opacity-60 cursor-not-allowed">
                <div>
                  <div className="flex items-center gap-2">
                    <p className="font-[700] text-textStrong">{item.label}</p>
                    <span className="rounded-full bg-muted/15 px-2 py-0.5 text-[10px] font-[800] uppercase tracking-wider text-muted">Yakında</span>
                  </div>
                  <p className="mt-0.5 text-sm text-muted">{item.description}</p>
                </div>
              </div>
            ) : (
              <Link key={item.href} href={item.href} className="flex items-center justify-between rounded-2xl border border-border bg-card px-6 py-5 transition-colors hover:border-primary/30 cursor-pointer">
                <div>
                  <p className="font-[700] text-textStrong">{item.label}</p>
                  <p className="mt-0.5 text-sm text-muted">{item.description}</p>
                </div>
                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className="shrink-0 text-muted"><path d="M9 18l6-6-6-6" /></svg>
              </Link>
            )
          )}
        </div>
      </PanelIcerikYuzeyi>
    </div>
  );
}

