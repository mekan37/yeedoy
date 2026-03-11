import '@/src/styles/globals.css';
import type { Metadata } from 'next';
import { Sora } from 'next/font/google';
import type { ReactNode } from 'react';
import { appConfig } from '@/src/lib/config';

const sora = Sora({
  subsets: ['latin'],
  variable: '--font-sora',
  display: 'swap',
});

export const metadata: Metadata = {
  metadataBase: new URL(appConfig.siteUrl()),
  title: {
    default: 'Yeedoy QR Menu',
    template: '%s | Yeedoy QR Menu',
  },
  description: 'High-performance public digital restaurant menu and QR generation experience.',
};

export default function RootLayout({ children }: { children: ReactNode }) {
  return (
    <html lang="tr">
      <body
        className={`${sora.variable} bg-bg text-text`}
        style={{ ['--yd-font-family' as any]: 'var(--font-sora), "Segoe UI", sans-serif' }}
      >
        {children}
      </body>
    </html>
  );
}

