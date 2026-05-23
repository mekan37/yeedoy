import type { ReactNode } from 'react';
import { SahipKabukIstemcisi } from '@/src/ui/kabuk/sahip-kabuk-istemcisi';

export default function OwnerLayout({ children }: { children: ReactNode }) {
  return <SahipKabukIstemcisi>{children}</SahipKabukIstemcisi>;
}
