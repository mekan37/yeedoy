import type { ReactNode } from 'react';
import { cn } from '@/src/lib/utils';

export function Badge({ children, className }: { children: ReactNode; className?: string }) {
  return (
    <span className={cn('inline-flex items-center rounded-full border border-slate-200 bg-slate-50 px-2 py-0.5 text-xs text-slate-600', className)}>
      {children}
    </span>
  );
}
