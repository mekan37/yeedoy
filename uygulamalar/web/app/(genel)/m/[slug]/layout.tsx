import { PublicShell } from '@/src/ui/acik/yerlesim';
import type { ReactNode } from 'react';

export default async function MenuSegmentLayout({ children }: { children: ReactNode }) {
  return <PublicShell>{children}</PublicShell>;
}
