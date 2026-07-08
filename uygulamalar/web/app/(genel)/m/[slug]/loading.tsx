export default function PublicMenuSlugLoading() {
  return (
    <div>
      {/* Business header skeleton */}
      <div className="border-b border-border bg-card">
        <div className="mx-auto max-w-7xl px-4 py-5 sm:px-6">
          <div className="mb-4 flex items-center gap-1.5">
            {[48, 72, 96, 48].map((w, i) => (
              <div key={i} className="h-3 animate-pulse rounded bg-border" style={{ width: w }} />
            ))}
          </div>
          <div className="flex flex-wrap gap-4">
            <div className="h-40 w-40 shrink-0 animate-pulse rounded-2xl bg-border" />
            <div className="flex-1 space-y-3 py-1" style={{ minWidth: 200 }}>
              <div className="h-7 w-48 animate-pulse rounded-lg bg-border" />
              <div className="h-4 w-56 animate-pulse rounded bg-border" />
              <div className="h-4 w-40 animate-pulse rounded bg-border" />
              <div className="mt-2 flex gap-2">
                <div className="h-9 w-24 animate-pulse rounded-full bg-border" />
                <div className="h-9 w-24 animate-pulse rounded-full bg-border" />
                <div className="h-9 w-28 animate-pulse rounded-2xl bg-border" />
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* 2-column body skeleton */}
      <div className="mx-auto flex max-w-7xl items-start gap-5 px-4 py-5 sm:px-6">
        {/* Sidebar */}
        <div className="hidden w-52 shrink-0 lg:block">
          <div className="overflow-hidden rounded-2xl border border-border bg-card py-3">
            <div className="mb-2 mx-4 h-3 w-28 animate-pulse rounded bg-border" />
            {Array.from({ length: 7 }).map((_, i) => (
              <div key={i} className="mx-2 my-1 h-9 animate-pulse rounded-xl bg-border" />
            ))}
          </div>
        </div>

        {/* Content */}
        <div className="flex-1 min-w-0 space-y-6">
          <div className="h-11 animate-pulse rounded-2xl bg-border" />
          <div className="grid grid-cols-2 gap-3 sm:grid-cols-4">
            {Array.from({ length: 4 }).map((_, i) => (
              <div key={i} className="aspect-square animate-pulse rounded-2xl bg-border" />
            ))}
          </div>
          <div>
            <div className="mb-3 h-6 w-32 animate-pulse rounded-lg bg-border" />
            <div className="overflow-hidden rounded-2xl border border-border">
              {Array.from({ length: 5 }).map((_, i) => (
                <div key={i} className="flex items-center gap-3 border-b border-border p-4 last:border-0">
                  <div className="h-20 w-20 shrink-0 animate-pulse rounded-xl bg-border" />
                  <div className="flex-1 space-y-2">
                    <div className="h-4 w-32 animate-pulse rounded bg-border" />
                    <div className="h-3 w-48 animate-pulse rounded bg-border" />
                    <div className="h-3 w-36 animate-pulse rounded bg-border" />
                  </div>
                  <div className="h-5 w-12 animate-pulse rounded bg-border" />
                </div>
              ))}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
