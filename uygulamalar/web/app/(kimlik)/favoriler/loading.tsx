import { SkeletonBusinessCard } from '@/src/ui/bilesenler/iskele';

export default function FavorilerLoading() {
  return (
    <main className="min-h-screen bg-bg py-10 px-4">
      <div className="mx-auto max-w-4xl">
        <div className="h-8 w-28 mb-6 animate-pulse rounded-xl bg-border" />
        <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 gap-4">
          {Array.from({ length: 6 }).map((_, i) => (
            <SkeletonBusinessCard key={i} />
          ))}
        </div>
      </div>
    </main>
  );
}
