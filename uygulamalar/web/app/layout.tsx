import '@/src/styles/globals.css';
import type { Metadata } from 'next';
import { Outfit, Inter } from 'next/font/google';
import type { ReactNode } from 'react';
import { Analytics } from '@vercel/analytics/next';
import { SpeedInsights } from '@vercel/speed-insights/next';
import { appConfig } from '@/src/lib/ayarlar';
import { AppProviders } from '@/src/lib/providers';

const outfit = Outfit({
  subsets: ['latin'],
  variable: '--font-outfit',
  display: 'swap',
  weight: ['400', '500', '600', '700', '800', '900'],
});

const inter = Inter({
  subsets: ['latin'],
  variable: '--font-inter',
  display: 'swap',
});

export const metadata: Metadata = {
  metadataBase: new URL(appConfig.siteUrl()),
  title: {
    default: 'Yeedoy QR Menu',
    template: '%s | Yeedoy QR Menu',
  },
  description: 'High-performance public digital restaurant menu and QR generation experience.',
  manifest: '/manifest.webmanifest',
  icons: {
    icon: [
      { url: '/favicon.svg', type: 'image/svg+xml' },
      { url: '/favicon.ico', sizes: 'any' },
      { url: '/favicon-32x32.png', sizes: '32x32', type: 'image/png' },
      { url: '/favicon-16x16.png', sizes: '16x16', type: 'image/png' },
    ],
    shortcut: '/favicon.svg',
    apple: [{ url: '/apple-touch-icon.png', sizes: '180x180', type: 'image/png' }],
  },
};

export default function RootLayout({ children }: { children: ReactNode }) {
  return (
    <html lang="tr" data-scroll-behavior="smooth">
      <head />
      <body
        className={`${outfit.variable} ${inter.variable} bg-bg text-text`}
        style={{
          ['--yd-font-family' as any]: 'var(--font-inter), "Segoe UI", sans-serif',
          ['--yd-font-display' as any]: 'var(--font-outfit), sans-serif',
        }}
      >
        <a
          href="#ana-icerik"
          className="sr-only focus:not-sr-only focus:fixed focus:left-4 focus:top-4 focus:z-[100] focus:rounded-xl focus:bg-primary focus:px-4 focus:py-2 focus:text-sm focus:font-bold focus:text-white"
        >
          İçeriğe geç
        </a>
        <div id="ana-icerik" tabIndex={-1}>
          <AppProviders>{children}</AppProviders>
        </div>
        <SpeedInsights />
        <Analytics />
      </body>
    </html>
  );
}

