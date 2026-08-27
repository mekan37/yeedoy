// arama/page.tsx'in ilk (sorgusuz) durumunu yansıtır: arama çubuğu başlığı +
// popüler aramalar/şehirler pill satırları + keşif kısayolları grid'i.
export default function SearchLoading() {
  return (
    <main className="min-h-screen bg-bg">
      <section className="border-b border-border bg-cardAlt py-8">
        <div className="mx-auto w-full max-w-6xl px-4 sm:px-6 lg:px-8">
          <div className="mb-5 space-y-2">
            <div className="h-7 w-24 animate-pulse rounded-xl bg-card" />
            <div className="h-4 w-52 animate-pulse rounded-lg bg-card" />
          </div>
          <div className="h-12 w-full animate-pulse rounded-2xl border border-border bg-card" />
        </div>
      </section>

      <div className="mx-auto w-full max-w-6xl px-4 py-8 sm:px-6 lg:px-8">
        {/* Popüler aramalar */}
        <section className="mb-8">
          <div className="mb-3 h-3 w-32 animate-pulse rounded-lg bg-card" />
          <div className="flex flex-wrap gap-2">
            {Array.from({ length: 8 }).map((_, i) => (
              <div key={i} className="h-10 w-24 animate-pulse rounded-full border border-border bg-card" />
            ))}
          </div>
        </section>

        {/* Şehre göre */}
        <section className="mb-8">
          <div className="mb-3 h-3 w-24 animate-pulse rounded-lg bg-card" />
          <div className="flex flex-wrap gap-2">
            {Array.from({ length: 5 }).map((_, i) => (
              <div key={i} className="h-10 w-28 animate-pulse rounded-full border border-border bg-card" />
            ))}
          </div>
        </section>

        {/* Keşfet kısayolları */}
        <section>
          <div className="mb-3 h-3 w-20 animate-pulse rounded-lg bg-card" />
          <div className="grid gap-3 sm:grid-cols-3">
            {[0, 1, 2].map((i) => (
              <div key={i} className="h-20 animate-pulse rounded-2xl border border-border bg-card" />
            ))}
          </div>
        </section>
      </div>
    </main>
  );
}
