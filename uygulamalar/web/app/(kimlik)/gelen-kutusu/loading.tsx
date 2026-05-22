import { SkeletonRow } from '@/src/ui/bilesenler/iskele';

export default function GelenKutusuLoading() {
  return (
    <main className="min-h-screen bg-bg py-10 px-4">
      <div className="mx-auto max-w-2xl">
        <div className="h-8 w-32 mb-6 animate-pulse rounded-xl bg-border" />
        <div className="rounded-2xl border border-border bg-card divide-y divide-border overflow-hidden">
          {Array.from({ length: 7 }).map((_, i) => (
            <SkeletonRow key={i} />
          ))}
        </div>
      </div>
    </main>
  );
}
