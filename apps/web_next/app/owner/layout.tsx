import type { ReactNode } from 'react';
import { OwnerShellClient } from '@/src/ui/shell/owner-shell-client';

export default function OwnerLayout({ children }: { children: ReactNode }) {
  return <OwnerShellClient>{children}</OwnerShellClient>;
}
