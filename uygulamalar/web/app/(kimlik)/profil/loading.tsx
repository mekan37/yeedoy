import { Skeleton, SkeletonText } from '@/src/ui/bilesenler/iskele';

export default function ProfilLoading() {
  return (
    <main className="bg-bg min-h-screen py-10 px-4">
      <div className="mx-auto max-w-2xl space-y-6">
        {/* Avatar + name */}
        <div className="flex items-center gap-4">
          <Skeleton className="h-20 w-20 rounded-full" />
          <div className="flex-1 space-y-2">
            <div className="h-6 w-36 animate-pulse rounded-lg bg-border" />
            <div className="h-4 w-24 animate-pulse rounded-lg bg-border" />
          </div>
        </div>
        {/* Stats row */}
        <div className="flex gap-4">
          {Array.from({ length: 3 }).map((_, i) => (
            <div key={i} className="flex-1 rounded-2xl border border-border bg-card p-4">
              <div className="h-6 w-10 mb-1 animate-pulse rounded-lg bg-border" />
              <div className="h-3 w-16 animate-pulse rounded-lg bg-border" />
            </div>
          ))}
        </div>
        {/* Activity */}
        <SkeletonText lines={3} />
      </div>
    </main>
  );
}
