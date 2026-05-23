import { SkeletonCard, SkeletonText, SkeletonRow } from '@/src/ui/bilesenler/iskele';

export default function BusinessLoading() {
  return (
    <main className="min-h-screen bg-bg">
      {/* Cover */}
      <div className="h-40 w-full animate-pulse sm:h-52" style={{ background: 'linear-gradient(135deg, rgba(127,29,29,0.3), rgba(220,38,38,0.2))' }} />

      <div className="mx-auto max-w-3xl px-4 sm:px-8 pt-16 pb-16">
        {/* Logo + info */}
        <div className="mb-6 flex items-start gap-4 flex-wrap">
          <div className="flex-1">
            <div className="h-8 w-48 mb-2 animate-pulse rounded-xl bg-border" />
            <div className="h-4 w-32 mb-3 animate-pulse rounded-lg bg-border" />
            <SkeletonText lines={2} />
          </div>
          <div className="h-10 w-28 animate-pulse rounded-xl bg-border" />
        </div>

        {/* Menus */}
        <div className="mb-8">
          <div className="h-6 w-24 mb-3 animate-pulse rounded-lg bg-border" />
          <div className="flex flex-col gap-2">
            <SkeletonRow className="rounded-2xl border border-border bg-card" />
            <SkeletonRow className="rounded-2xl border border-border bg-card" />
          </div>
        </div>

        {/* Reviews */}
        <div>
          <div className="h-6 w-24 mb-4 animate-pulse rounded-lg bg-border" />
          <div className="flex flex-col gap-4">
            <SkeletonCard />
            <SkeletonCard />
            <SkeletonCard />
          </div>
        </div>
      </div>
    </main>
  );
}
