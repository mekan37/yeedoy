import type { Metadata } from 'next';
import Link from 'next/link';
import { PanelPageHeader } from '@/src/ui/layout/panel-page-header';
import { PanelContentSurface } from '@/src/ui/layout/panel-section-card';

export const metadata: Metadata = {
  title: 'Ayarlar | Owner Panel',
  robots: { index: false, follow: false },
};

const SETTINGS_ITEMS = [
  { href: '/owner/settings/hours', label: 'Çalışma Saatleri', description: 'Günlük açılış/kapanış saatlerini ayarlayın' },
  { href: '/owner/settings/domain', label: 'Özel Domain', description: 'İşletmenize özel alan adı bağlayın' },
];

export default function OwnerSettingsPage() {
  return (
    <div className="flex flex-col">
      <PanelPageHeader eyebrow="Owner" title="Ayarlar" description="İşletme yapılandırma ve tercihler" />
      <PanelContentSurface className="pt-6">
        <div className="flex flex-col gap-3 max-w-lg">
          {SETTINGS_ITEMS.map((item) => (
            <Link key={item.href} href={item.href} className="flex items-center justify-between rounded-2xl border border-border bg-card px-6 py-5 transition-colors hover:border-primary/30 cursor-pointer">
              <div>
                <p className="font-[700] text-textStrong">{item.label}</p>
                <p className="mt-0.5 text-sm text-muted">{item.description}</p>
              </div>
              <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className="shrink-0 text-muted"><path d="M9 18l6-6-6-6" /></svg>
            </Link>
          ))}
        </div>
      </PanelContentSurface>
    </div>
  );
}
