import * as React from 'react';
import { cn } from '@/src/lib/utils';

export function Input({ className, ...props }: React.InputHTMLAttributes<HTMLInputElement>) {
  return (
    <input
      className={cn(
        'h-11 w-full rounded-xl border border-slate-200 bg-white px-3 text-sm text-slate-900 outline-none ring-0 placeholder:text-slate-400 focus:border-slate-400 focus:shadow-[0_0_0_3px_rgba(148,163,184,0.18)]',
        className,
      )}
      {...props}
    />
  );
}
