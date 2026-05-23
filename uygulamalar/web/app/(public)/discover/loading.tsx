import { SkeletonBusinessCard } from '@/src/ui/components/skeleton';

export default function DiscoverLoading() {
  return (
    <main className="min-h-screen bg-bg py-10 px-4">
      <div className="max-w-5xl mx-auto">
        {/* Header */}
        <div className="h-9 w-36 mb-2 animate-pulse rounded-xl bg-border" />
        <div className="h-5 w-64 mb-8 animate-pulse rounded-lg bg-border" />

        {/* Filter row */}
        <div className="flex flex-wrap gap-3 mb-8">
          <div className="h-10 flex-1 min-w-[180px] animate-pulse rounded-xl bg-border" />
          <div className="h-10 w-36 animate-pulse rounded-xl bg-border" />
          <div className="h-10 w-40 animate-pulse rounded-xl bg-border" />
          <div className="h-10 w-16 animate-pulse rounded-xl bg-border" />
        </div>

        {/* Count */}
        <div className="h-4 w-40 mb-4 animate-pulse rounded-lg bg-border" />

        {/* Grid */}
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
          {Array.from({ length: 9 }).map((_, i) => (
            <SkeletonBusinessCard key={i} />
          ))}
        </div>
      </div>
    </main>
  );
}
