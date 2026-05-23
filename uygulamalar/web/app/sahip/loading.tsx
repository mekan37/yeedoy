import { SkeletonMetricGrid, SkeletonRow } from '@/src/ui/bilesenler/iskele';

export default function OwnerLoading() {
  return (
    <div className="flex flex-col">
      {/* Page header skeleton */}
      <div className="border-b border-border bg-card px-6 py-5">
        <div className="mx-auto max-w-[1520px]">
          <div className="h-3 w-20 mb-2 animate-pulse rounded-lg bg-border" />
          <div className="h-7 w-48 animate-pulse rounded-xl bg-border" />
        </div>
      </div>

      <div className="mx-auto w-full max-w-[1520px] px-4 pt-6 sm:px-6">
        <SkeletonMetricGrid count={4} />

        <div className="mt-6 rounded-2xl border border-border bg-card overflow-hidden">
          <div className="px-5 py-3 border-b border-border">
            <div className="h-4 w-32 animate-pulse rounded-lg bg-border" />
          </div>
          <SkeletonRow />
          <SkeletonRow />
          <SkeletonRow />
          <SkeletonRow />
          <SkeletonRow />
        </div>
      </div>
    </div>
  );
}
