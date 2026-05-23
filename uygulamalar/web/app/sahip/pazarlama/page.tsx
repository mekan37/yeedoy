import type { Metadata } from 'next';
import Link from 'next/link';
import { type ReactNode } from 'react';
import { PanelSayfaBasligi } from '@/src/ui/yerlesim/panel-page-header';
import { PanelIcerikYuzeyi } from '@/src/ui/yerlesim/panel-section-card';

export const metadata: Metadata = {
  title: 'Pazarlama | Sahip Paneli',
  robots: { index: false, follow: false },
};

const MARKETING_ITEMS: Array<{ href: string; label: string; description: string; icon: ReactNode; badge?: string }> = [
  {
    href: '/sahip/pazarlama/kampanyalar',
    label: 'Push Bildirimleri',
    description: 'Segmentlere hedefli bildirim gönder',
    icon: <BellIcon />,
  },
  {
    href: '/sahip/pazarlama/e-posta',
    label: 'E-posta Kampanyaları',
    description: '4 hazır şablon + önizleme + geçmiş',
    icon: <MailIcon />,
  },
  {
    href: '/sahip/pazarlama/sms',
    label: 'SMS Pazarlama',
    description: 'Takipçi ve sadakat kartlılara kısa mesaj',
    icon: <SmsIcon />,
  },
  {
    href: '/sahip/pazarlama/sadakat',
    label: 'Sadakat Programı',
    description: 'Müşteri puan ve ödül sistemi yönetimi',
    icon: <StarIcon />,
  },
  {
    href: '/sahip/pazarlama/otomasyonlar',
    label: 'Otomasyonlar',
    description: 'Tetikleyici tabanlı pazarlama akışları',
    icon: <ZapIcon />,
  },
];

export default function OwnerMarketingPage() {
  return (
    <div className="flex flex-col">
      <PanelSayfaBasligi eyebrow="Owner" title="Pazarlama" description="Müşterilerinize ulaşmak için pazarlama araçları" />
      <PanelIcerikYuzeyi className="pt-6">
        <div className="grid gap-4 sm:grid-cols-2">
          {MARKETING_ITEMS.map((item) => (
            <Link
              key={item.href}
              href={item.href}
              className="flex cursor-pointer items-start gap-4 rounded-2xl border border-border bg-card p-6 transition-colors hover:border-primary/30 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary/30"
            >
              <span className="flex h-10 w-10 shrink-0 items-center justify-center rounded-xl border border-border bg-bg text-muted">
                {item.icon}
              </span>
              <div className="min-w-0 flex-1">
                <div className="flex items-center gap-2">
                  <p className="font-[700] text-textStrong">{item.label}</p>
                  {item.badge && (
                    <span className="rounded-full bg-amber-50 px-2 py-0.5 text-[10px] font-[700] text-amber-700">
                      {item.badge}
                    </span>
                  )}
                </div>
                <p className="mt-0.5 text-sm text-muted">{item.description}</p>
              </div>
            </Link>
          ))}
        </div>
      </PanelIcerikYuzeyi>
    </div>
  );
}

function StarIcon() {
  return (
    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
      <polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2" />
    </svg>
  );
}

function BellIcon() {
  return (
    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
      <path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9" />
      <path d="M13.73 21a2 2 0 0 1-3.46 0" />
    </svg>
  );
}

function MailIcon() {
  return (
    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
      <path d="M4 4h16c1.1 0 2 .9 2 2v12c0 1.1-.9 2-2 2H4c-1.1 0-2-.9-2-2V6c0-1.1.9-2 2-2z" />
      <polyline points="22,6 12,13 2,6" />
    </svg>
  );
}

function ZapIcon() {
  return (
    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
      <polygon points="13 2 3 14 12 14 11 22 21 10 12 10 13 2" />
    </svg>
  );
}

function SmsIcon() {
  return (
    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
      <path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z" />
      <line x1="8" y1="10" x2="16" y2="10" />
      <line x1="8" y1="14" x2="12" y2="14" />
    </svg>
  );
}

