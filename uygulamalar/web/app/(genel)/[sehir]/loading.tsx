// [sehir]/page.tsx'in gerçek yerleşimini yansıtır: breadcrumb + başlık +
// popüler kategoriler (pill satırı) + ilçeler grid'i (rounded-2xl kartlar).
export default function CityHubLoading() {
  return (
    <main className="min-h-screen bg-bg">
      <div className="mx-auto w-full max-w-6xl px-4 py-8 sm:px-6 lg:px-8">
        {/* Breadcrumb */}
        <div className="mb-4 h-4 w-40 animate-pulse rounded-lg bg-card" />

        {/* Başlık + alt satır */}
        <div className="mb-8 space-y-2">
          <div className="h-8 w-56 animate-pulse rounded-xl bg-card" />
          <div className="h-4 w-44 animate-pulse rounded-lg bg-card" />
        </div>

        {/* Popüler kategoriler */}
        <section className="mb-8">
          <div className="mb-3 h-5 w-44 animate-pulse rounded-lg bg-card" />
          <div className="flex flex-wrap gap-2">
            {[0, 1, 2, 3, 4, 5].map((i) => (
              <div key={i} className="h-8 w-24 animate-pulse rounded-xl border border-border bg-card" />
            ))}
          </div>
        </section>

        {/* İlçeler */}
        <section>
          <div className="mb-3 h-5 w-24 animate-pulse rounded-lg bg-card" />
          <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-3">
            {Array.from({ length: 9 }).map((_, i) => (
              <div key={i} className="h-24 animate-pulse rounded-2xl border border-border bg-card" />
            ))}
          </div>
        </section>
      </div>
    </main>
  );
}
