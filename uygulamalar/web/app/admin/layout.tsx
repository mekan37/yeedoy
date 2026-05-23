import type { ReactNode } from 'react';
import { AdminShellClient } from '@/src/ui/shell/admin-shell-client';

export default function AdminLayout({ children }: { children: ReactNode }) {
  return <AdminShellClient>{children}</AdminShellClient>;
}
