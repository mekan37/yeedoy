import '@/src/styles/globals.css';
import type { Metadata } from 'next';
import { Sora, Playfair_Display } from 'next/font/google';
import type { ReactNode } from 'react';
import { appConfig } from '@/src/lib/config';
import { AppProviders } from '@/src/lib/providers';

const sora = Sora({
  subsets: ['latin'],
  variable: '--font-sora',
  display: 'swap',
});

const playfair = Playfair_Display({
  subsets: ['latin'],
  variable: '--font-playfair',
  display: 'swap',
  weight: ['400', '700', '900'],
});

export const metadata: Metadata = {
  metadataBase: new URL(appConfig.siteUrl()),
  title: {
    default: 'Yeedoy QR Menu',
    template: '%s | Yeedoy QR Menu',
  },
  description: 'High-performance public digital restaurant menu and QR generation experience.',
  icons: {
    icon: '/favicon.svg',
  },
};

export default function RootLayout({ children }: { children: ReactNode }) {
  return (
    <html lang="tr">
      <body
        className={`${sora.variable} ${playfair.variable} bg-bg text-text`}
        style={{ ['--yd-font-family' as any]: 'var(--font-sora), "Segoe UI", sans-serif' }}
      >
        <AppProviders>{children}</AppProviders>
      </body>
    </html>
  );
}

