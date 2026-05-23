import { SkeletonCard } from '@/src/ui/bilesenler/iskele';

export default function FeedLoading() {
  return (
    <main className="min-h-screen bg-bg">
      <div className="mx-auto max-w-2xl px-4 py-12">
        <div className="mb-8">
          <div className="h-3 w-20 mb-2 animate-pulse rounded-lg bg-border" />
          <div className="h-9 w-44 mb-2 animate-pulse rounded-xl bg-border" />
          <div className="h-4 w-64 animate-pulse rounded-lg bg-border" />
        </div>
        <div className="flex flex-col gap-4">
          {Array.from({ length: 6 }).map((_, i) => <SkeletonCard key={i} />)}
        </div>
      </div>
    </main>
  );
}
