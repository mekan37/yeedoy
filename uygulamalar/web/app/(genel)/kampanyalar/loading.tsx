// KampanyalarCanli'nin (src/ui/acik/kampanyalar-canli.tsx) gerçek yerleşimini yansıtır:
// başlık + sekme/sıralama satırı + sol filtre sidebar + sağ kampanya kartı grid'i (16/10 görsel).
export default function KampanyalarLoading() {
  return (
    <main className="min-h-screen bg-bg">
      <div className="mx-auto max-w-7xl px-4 py-8 sm:px-6">
        {/* Başlık + sekmeler/sıralama */}
        <div className="mb-6 flex flex-wrap items-start gap-4">
          <div className="shrink-0 space-y-2">
            <div className="h-7 w-44 animate-pulse rounded-xl bg-card" />
            <div className="h-4 w-56 animate-pulse rounded-lg bg-card" />
          </div>
          <div className="flex flex-1 flex-wrap items-center justify-end gap-2">
            {[0, 1, 2, 3, 4].map((i) => (
              <div key={i} className="h-9 w-20 animate-pulse rounded-xl border border-border bg-card" />
            ))}
            <div className="h-9 w-32 animate-pulse rounded-xl border border-border bg-card" />
          </div>
        </div>

        <div className="flex flex-col gap-6 lg:flex-row lg:items-start">
          {/* Sol filtre sidebar */}
          <aside className="w-full space-y-6 rounded-2xl border border-border bg-card p-5 lg:w-56 lg:shrink-0">
            <div className="h-4 w-16 animate-pulse rounded-lg bg-cardAlt" />
            <div className="h-10 w-full animate-pulse rounded-xl bg-cardAlt" />
            <div className="h-10 w-full animate-pulse rounded-xl bg-cardAlt" />
            <div className="space-y-2">
              {[0, 1, 2, 3].map((i) => (
                <div key={i} className="h-4 w-3/4 animate-pulse rounded-lg bg-cardAlt" />
              ))}
            </div>
            <div className="flex gap-1.5">
              {[0, 1, 2, 3].map((i) => (
                <div key={i} className="h-9 flex-1 animate-pulse rounded-lg bg-cardAlt" />
              ))}
            </div>
          </aside>

          {/* Sağ: kampanya kartları grid'i */}
          <div className="min-w-0 flex-1">
            <div className="mb-4 h-3 w-32 animate-pulse rounded-lg bg-card" />
            <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 xl:grid-cols-3">
              {Array.from({ length: 6 }).map((_, i) => (
                <div key={i} className="overflow-hidden rounded-[20px] border border-border bg-card">
                  <div className="w-full animate-pulse bg-cardAlt" style={{ aspectRatio: '16/10' }} />
                  <div className="space-y-2 p-3">
                    <div className="h-4 w-4/5 animate-pulse rounded-lg bg-cardAlt" />
                    <div className="h-3 w-3/5 animate-pulse rounded-lg bg-cardAlt" />
                    <div className="h-8 w-full animate-pulse rounded-xl bg-cardAlt" />
                  </div>
                </div>
              ))}
            </div>

            {/* CTA banner */}
            <div className="mt-10 h-20 w-full animate-pulse rounded-2xl border border-border bg-card" />
          </div>
        </div>
      </div>
    </main>
  );
}
