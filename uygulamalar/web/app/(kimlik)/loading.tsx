import { SkeletonCard, SkeletonText } from '@/src/ui/bilesenler/iskele';

export default function AuthLoading() {
  return (
    <main className="min-h-screen bg-bg">
      <div className="mx-auto max-w-2xl px-4 py-12">
        {/* Back link */}
        <div className="mb-6 h-5 w-24 animate-pulse rounded-lg bg-border" />

        {/* Title */}
        <div className="mb-6 h-8 w-48 animate-pulse rounded-xl bg-border" />

        {/* Content cards */}
        <div className="flex flex-col gap-3">
          <SkeletonCard />
          <SkeletonCard />
          <SkeletonCard />
          <SkeletonText lines={2} className="mt-4" />
        </div>
      </div>
    </main>
  );
}
