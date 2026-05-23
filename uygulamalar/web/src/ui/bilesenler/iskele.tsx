import type { ReactNode } from 'react';

export function Skeleton({ className = '' }: { className?: string }) {
  return (
    <div
      className={`animate-pulse rounded-xl bg-border ${className}`}
      role="status"
      aria-label="Yükleniyor"
    />
  );
}

export function SkeletonText({ lines = 1, className = '' }: { lines?: number; className?: string }) {
  return (
    <div className={`flex flex-col gap-2 ${className}`} role="status" aria-label="Yükleniyor">
      {Array.from({ length: lines }).map((_, i) => (
        <div
          key={i}
          className={`h-4 animate-pulse rounded-lg bg-border ${i === lines - 1 && lines > 1 ? 'w-3/4' : 'w-full'}`}
        />
      ))}
    </div>
  );
}

export function SkeletonCard({ className = '' }: { className?: string }) {
  return (
    <div className={`rounded-2xl border border-border bg-card p-5 ${className}`} role="status" aria-label="Yükleniyor">
      <div className="flex items-start gap-3 mb-3">
        <div className="h-10 w-10 shrink-0 animate-pulse rounded-xl bg-border" />
        <div className="flex-1 space-y-2">
          <div className="h-4 w-2/3 animate-pulse rounded-lg bg-border" />
          <div className="h-3 w-1/2 animate-pulse rounded-lg bg-border" />
        </div>
      </div>
      <SkeletonText lines={2} />
    </div>
  );
}

export function SkeletonRow({ className = '' }: { className?: string }) {
  return (
    <div className={`flex items-center gap-4 px-5 py-4 ${className}`} role="status">
      <div className="h-10 w-10 shrink-0 animate-pulse rounded-xl bg-border" />
      <div className="flex-1 space-y-2">
        <div className="h-4 w-1/2 animate-pulse rounded-lg bg-border" />
        <div className="h-3 w-1/3 animate-pulse rounded-lg bg-border" />
      </div>
      <div className="h-6 w-16 shrink-0 animate-pulse rounded-full bg-border" />
    </div>
  );
}

export function SkeletonMetricGrid({ count = 4 }: { count?: number }) {
  return (
    <div className={`grid grid-cols-2 gap-4 sm:grid-cols-${Math.min(count, 4)}`} role="status">
      {Array.from({ length: count }).map((_, i) => (
        <div key={i} className="rounded-2xl border border-border bg-card p-5">
          <div className="h-8 w-8 mb-3 animate-pulse rounded-xl bg-border" />
          <div className="h-7 w-1/2 mb-1 animate-pulse rounded-lg bg-border" />
          <div className="h-3 w-2/3 animate-pulse rounded-lg bg-border" />
        </div>
      ))}
    </div>
  );
}

export function SkeletonTableRows({ rows = 5, cols = 4 }: { rows?: number; cols?: number }) {
  return (
    <>
      {Array.from({ length: rows }).map((_, i) => (
        <tr key={i} className="border-b border-border">
          {Array.from({ length: cols }).map((_, j) => (
            <td key={j} className="px-5 py-3">
              <div className={`h-4 animate-pulse rounded-lg bg-border ${j === 0 ? 'w-32' : 'w-24'}`} />
            </td>
          ))}
        </tr>
      ))}
    </>
  );
}

export function SkeletonBusinessCard({ className = '' }: { className?: string }) {
  return (
    <div className={`rounded-2xl border border-border bg-card overflow-hidden ${className}`} role="status">
      <div className="h-36 w-full animate-pulse bg-border" />
      <div className="p-4 space-y-2">
        <div className="h-5 w-3/4 animate-pulse rounded-lg bg-border" />
        <div className="flex gap-2">
          <div className="h-5 w-20 animate-pulse rounded-full bg-border" />
          <div className="h-5 w-16 animate-pulse rounded-full bg-border" />
        </div>
      </div>
    </div>
  );
}

export function SkeletonHero({ children }: { children?: ReactNode }) {
  return (
    <div className="relative bg-textStrong" role="status" aria-label="Yükleniyor">
      <div className="h-40 w-full animate-pulse opacity-20 sm:h-52" style={{ background: 'linear-gradient(135deg, #7f1d1d, #dc2626)' }} />
      {children}
    </div>
  );
}
