import { SkeletonBusinessCard } from '@/src/ui/bilesenler/iskele';

export default function EnIyilerLoading() {
  return (
    <main className="min-h-screen bg-bg py-10 px-4">
      <div className="max-w-5xl mx-auto">
        <div className="h-9 w-32 mb-2 animate-pulse rounded-xl bg-border" />
        <div className="h-5 w-72 mb-8 animate-pulse rounded-lg bg-border" />
        <div className="flex gap-2 mb-6">
          {Array.from({ length: 4 }).map((_, i) => (
            <div key={i} className="h-8 w-20 animate-pulse rounded-full bg-border" />
          ))}
        </div>
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
          {Array.from({ length: 9 }).map((_, i) => (
            <SkeletonBusinessCard key={i} />
          ))}
        </div>
      </div>
    </main>
  );
}
