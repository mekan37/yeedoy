export default function EnIyilerLoading() {
  return (
    <div className="min-h-screen bg-bg">
      <div className="mx-auto max-w-7xl px-4 py-8 sm:px-6">
        {/* Breadcrumb */}
        <div className="mb-5 h-4 w-36 animate-pulse rounded bg-border" />

        {/* Başlık + kategori tab'ları */}
        <div className="mb-6 flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
          <div>
            <div className="h-8 w-64 animate-pulse rounded-xl bg-border" />
            <div className="mt-2 h-4 w-48 animate-pulse rounded-lg bg-border" />
          </div>
          <div className="flex gap-2">
            {Array.from({ length: 5 }).map((_, i) => (
              <div key={i} className="h-8 w-20 shrink-0 animate-pulse rounded-full bg-border" />
            ))}
          </div>
        </div>

        {/* 2-kolon */}
        <div className="flex flex-col gap-6 lg:flex-row">
          {/* Sidebar */}
          <div className="h-80 w-full shrink-0 animate-pulse rounded-2xl bg-border lg:w-56" />

          {/* Grid */}
          <div className="flex-1">
            <div className="mb-4 h-4 w-32 animate-pulse rounded bg-border" />
            <ol className="grid grid-cols-1 gap-4 sm:grid-cols-2 xl:grid-cols-3">
              {Array.from({ length: 6 }).map((_, i) => (
                <li key={i} className="overflow-hidden rounded-[20px] border border-border bg-card">
                  <div className="w-full animate-pulse bg-border" style={{ aspectRatio: '4/3' }} />
                  <div className="space-y-2 p-3">
                    <div className="h-4 w-3/4 animate-pulse rounded bg-border" />
                    <div className="h-3 w-1/2 animate-pulse rounded bg-border" />
                    <div className="h-3 w-1/3 animate-pulse rounded bg-border" />
                    <div className="mt-3 h-8 animate-pulse rounded-lg bg-border" />
                  </div>
                </li>
              ))}
            </ol>
          </div>
        </div>
      </div>
    </div>
  );
}
