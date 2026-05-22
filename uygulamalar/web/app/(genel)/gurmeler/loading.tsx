import { SkeletonCard } from '@/src/ui/bilesenler/iskele';

export default function GurmellerLoading() {
  return (
    <main className="min-h-screen bg-bg py-10 px-4">
      <div className="mx-auto max-w-3xl">
        <div className="h-8 w-28 mb-2 animate-pulse rounded-xl bg-border" />
        <div className="h-4 w-56 mb-8 animate-pulse rounded-lg bg-border" />
        <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
          {Array.from({ length: 8 }).map((_, i) => (
            <SkeletonCard key={i} />
          ))}
        </div>
      </div>
    </main>
  );
}
