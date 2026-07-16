import type { Metadata } from 'next';
import type { ReactNode } from 'react';
import { SahipKabukIstemcisi } from '@/src/ui/kabuk/sahip-kabuk-istemcisi';

export const metadata: Metadata = {
  robots: { index: false, follow: false },
};

export default function OwnerLayout({ children }: { children: ReactNode }) {
  return <SahipKabukIstemcisi>{children}</SahipKabukIstemcisi>;
}
