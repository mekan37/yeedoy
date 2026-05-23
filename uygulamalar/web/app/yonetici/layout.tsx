import type { ReactNode } from 'react';
import { YoneticiKabukIstemcisi } from '@/src/ui/kabuk/yonetici-kabuk-istemcisi';

export default function AdminLayout({ children }: { children: ReactNode }) {
  return <YoneticiKabukIstemcisi>{children}</YoneticiKabukIstemcisi>;
}
