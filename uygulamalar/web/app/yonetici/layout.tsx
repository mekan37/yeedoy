import type { Metadata } from 'next';
import type { ReactNode } from 'react';
import { YoneticiKabukIstemcisi } from '@/src/ui/kabuk/yonetici-kabuk-istemcisi';

export const metadata: Metadata = {
  robots: { index: false, follow: false },
};

export default function AdminLayout({ children }: { children: ReactNode }) {
  return <YoneticiKabukIstemcisi>{children}</YoneticiKabukIstemcisi>;
}
