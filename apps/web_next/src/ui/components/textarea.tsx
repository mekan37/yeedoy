import * as React from 'react';
import { cn } from '@/src/lib/utils';

export function Textarea({ className, ...props }: React.TextareaHTMLAttributes<HTMLTextAreaElement>) {
  return (
    <textarea
      className={cn(
        'min-h-20 w-full rounded-xl border border-slate-200 bg-white px-3 py-2 text-sm text-slate-900 outline-none placeholder:text-slate-400 focus:border-slate-400 focus:shadow-[0_0_0_3px_rgba(148,163,184,0.18)]',
        className,
      )}
      {...props}
    />
  );
}
