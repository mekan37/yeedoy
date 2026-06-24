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

// Inline script — runs synchronously before paint to avoid flash
const themeScript = `(function(){
  try {
    var s = localStorage.getItem('yd-theme');
    var dark = s === 'dark' || (!s && window.matchMedia('(prefers-color-scheme: dark)').matches);
    if (dark) document.documentElement.classList.add('dark');
    else if (s === 'light') document.documentElement.classList.add('light');
  } catch(e) {}
})()`;

export default function RootLayout({ children }: { children: ReactNode }) {
  return (
    <html lang="tr" suppressHydrationWarning>
      {/* eslint-disable-next-line @next/next/no-sync-scripts */}
      <head>
        <script dangerouslySetInnerHTML={{ __html: themeScript }} />
      </head>
      <body
        className={`${sora.variable} ${playfair.variable} bg-bg text-text`}
        style={{ ['--yd-font-family' as any]: 'var(--font-sora), "Segoe UI", sans-serif' }}
      >
        <AppProviders>{children}</AppProviders>
      </body>
    </html>
  );
}

