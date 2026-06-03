import type { Metadata } from 'next';
import type { ReactNode } from 'react';
import { OwnerShellClient } from '@/src/ui/shell/owner-shell-client';

export const metadata: Metadata = {
  robots: { index: false, follow: false },
};

export default function OwnerLayout({ children }: { children: ReactNode }) {
  return <OwnerShellClient>{children}</OwnerShellClient>;
}
