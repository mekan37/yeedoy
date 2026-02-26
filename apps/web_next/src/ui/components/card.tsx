import { cn } from '@/src/lib/utils';
import type { ReactNode } from 'react';

export function Card({ className, children }: { className?: string; children: ReactNode }) {
  return (
    <div
      className={cn(
        'rounded-[20px] border border-slate-200/90 bg-white p-5 shadow-[0_10px_30px_-20px_rgba(15,23,42,0.55)]',
        className,
      )}
    >
      {children}
    </div>
  );
}
