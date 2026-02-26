import '@/src/styles/globals.css';
import type { Metadata } from 'next';
import type { ReactNode } from 'react';
import { colorRgbVars } from '@/src/theme/colors';

export const metadata: Metadata = {
  title: 'Yeedoy Digital QR Menu',
  description: 'Digital QR menu builder for businesses',
};

export default function RootLayout({ children }: { children: ReactNode }) {
  const cssVars: Record<string, string> = Object.fromEntries(
    Object.entries(colorRgbVars).map(([token, rgb]) => [`--${token}`, rgb]),
  );

  return (
    <html lang="tr">
      <body style={cssVars} className="bg-bg text-text">
        {children}
      </body>
    </html>
  );
}

