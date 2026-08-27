// fiyat-endeksi/page.tsx için özel iskelet: hero + istatistik kartları + "neden şimdi" kartları
// + canlı fiyat tablosu + fiyat seviyeleri + veri hikayeleri grid'i + CTA blokları + metodoloji
// bölümünü yansıtır. Sayfa `revalidate = 3600` olsa da RPC verisi her istekte sunucuda
// hesaplandığından ilk yüklemede bu iskelet görünür.
export default function FiyatEndeksiLoading() {
  return (
    <div className="min-h-screen bg-bg pb-20 text-text md:pb-0">
      {/* Hero */}
      <section className="border-b border-border bg-card">
        <div className="mx-auto w-full max-w-6xl px-4 py-16 text-center sm:px-6 lg:px-8">
          <div className="mx-auto mb-3 h-3 w-56 animate-pulse rounded-full bg-cardAlt" />
          <div className="mx-auto mb-2 h-10 w-80 animate-pulse rounded-xl bg-cardAlt" />
          <div className="mx-auto mb-4 h-10 w-64 animate-pulse rounded-xl bg-cardAlt" />
          <div className="mx-auto mb-2 h-4 w-full max-w-xl animate-pulse rounded-lg bg-cardAlt" />
          <div className="mx-auto mb-8 h-4 w-2/3 max-w-xl animate-pulse rounded-lg bg-cardAlt" />
          <div className="flex flex-wrap items-center justify-center gap-3">
            <div className="h-[52px] w-40 animate-pulse rounded-2xl bg-cardAlt" />
            <div className="h-[52px] w-44 animate-pulse rounded-2xl bg-cardAlt" />
          </div>
        </div>
      </section>

      {/* Özet istatistikler */}
      <section className="border-b border-border">
        <div className="mx-auto w-full max-w-6xl px-4 py-10 sm:px-6 lg:px-8">
          <div className="grid gap-4 sm:grid-cols-3">
            {[0, 1, 2].map((i) => (
              <div key={i} className="rounded-2xl border border-border bg-card p-5">
                <div className="h-3 w-32 animate-pulse rounded-full bg-cardAlt" />
                <div className="mt-2 h-8 w-20 animate-pulse rounded-lg bg-cardAlt" />
                <div className="mt-1 h-3 w-24 animate-pulse rounded-full bg-cardAlt" />
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* Neden Şimdi? */}
      <section className="border-b border-border">
        <div className="mx-auto w-full max-w-6xl px-4 py-14 sm:px-6 lg:px-8">
          <div className="mb-8 space-y-2">
            <div className="h-3 w-24 animate-pulse rounded-full bg-card" />
            <div className="h-7 w-56 animate-pulse rounded-xl bg-card" />
          </div>
          <div className="grid gap-5 sm:grid-cols-3">
            {[0, 1, 2].map((i) => (
              <div key={i} className="rounded-2xl border border-border bg-card p-6">
                <div className="mb-4 h-12 w-12 animate-pulse rounded-2xl bg-cardAlt" />
                <div className="mb-1 h-3 w-16 animate-pulse rounded-full bg-cardAlt" />
                <div className="mb-2 h-5 w-32 animate-pulse rounded-lg bg-cardAlt" />
                <div className="h-3 w-full animate-pulse rounded-full bg-cardAlt" />
                <div className="mt-1.5 h-3 w-4/5 animate-pulse rounded-full bg-cardAlt" />
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* Canlı Fiyat Endeksi Tablosu */}
      <section className="border-b border-border">
        <div className="mx-auto w-full max-w-6xl px-4 py-14 sm:px-6 lg:px-8">
          <div className="mb-8 flex flex-wrap items-end justify-between gap-4">
            <div className="space-y-2">
              <div className="h-3 w-20 animate-pulse rounded-full bg-card" />
              <div className="h-7 w-72 animate-pulse rounded-xl bg-card" />
            </div>
            <div className="h-11 w-32 shrink-0 animate-pulse rounded-xl bg-card" />
          </div>
          <div className="overflow-hidden rounded-2xl border border-border bg-card">
            <div className="border-b border-border px-5 py-3.5">
              <div className="flex justify-between gap-4">
                {[0, 1, 2, 3, 4].map((i) => (
                  <div key={i} className="h-2.5 w-16 animate-pulse rounded-full bg-cardAlt" />
                ))}
              </div>
            </div>
            {[0, 1, 2, 3, 4, 5].map((i) => (
              <div key={i} className="flex justify-between gap-4 border-b border-border px-5 py-3.5 last:border-0">
                <div className="h-3.5 w-28 animate-pulse rounded-full bg-cardAlt" />
                <div className="h-3.5 w-14 animate-pulse rounded-full bg-cardAlt" />
                <div className="h-3.5 w-14 animate-pulse rounded-full bg-cardAlt" />
                <div className="h-3.5 w-10 animate-pulse rounded-full bg-cardAlt" />
                <div className="h-3.5 w-8 animate-pulse rounded-full bg-cardAlt" />
              </div>
            ))}
          </div>
          <div className="mt-4 h-3 w-3/4 animate-pulse rounded-full bg-card" />
        </div>
      </section>

      {/* Fiyat Seviyeleri */}
      <section className="border-b border-border">
        <div className="mx-auto w-full max-w-6xl px-4 py-14 sm:px-6 lg:px-8">
          <div className="mb-8 space-y-2">
            <div className="h-3 w-24 animate-pulse rounded-full bg-card" />
            <div className="h-7 w-48 animate-pulse rounded-xl bg-card" />
          </div>
          <div className="grid gap-5 sm:grid-cols-3">
            {[0, 1, 2].map((i) => (
              <div key={i} className="rounded-2xl border border-border bg-card p-6">
                <div className="mb-2 h-7 w-12 animate-pulse rounded-lg bg-cardAlt" />
                <div className="mb-2 h-5 w-24 animate-pulse rounded-lg bg-cardAlt" />
                <div className="h-3 w-full animate-pulse rounded-full bg-cardAlt" />
                <div className="mt-1.5 h-3 w-2/3 animate-pulse rounded-full bg-cardAlt" />
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* Veri Hikayeleri */}
      <section className="border-b border-border">
        <div className="mx-auto w-full max-w-6xl px-4 py-14 sm:px-6 lg:px-8">
          <div className="mb-8 space-y-2">
            <div className="h-3 w-24 animate-pulse rounded-full bg-card" />
            <div className="h-7 w-80 animate-pulse rounded-xl bg-card" />
          </div>
          <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
            {[0, 1, 2, 3, 4, 5].map((i) => (
              <div key={i} className="rounded-2xl border border-border bg-card p-6">
                <div className="mb-3 flex items-center justify-between">
                  <div className="h-8 w-8 animate-pulse rounded-xl bg-cardAlt" />
                  <div className="h-5 w-20 animate-pulse rounded-full bg-cardAlt" />
                </div>
                <div className="mb-2 h-4 w-full animate-pulse rounded-full bg-cardAlt" />
                <div className="mb-4 h-3 w-4/5 animate-pulse rounded-full bg-cardAlt" />
                <div className="h-2.5 w-28 animate-pulse rounded-full bg-cardAlt" />
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* CTA blokları */}
      <section className="border-b border-border">
        <div className="mx-auto w-full max-w-6xl px-4 py-14 sm:px-6 lg:px-8">
          <div className="mb-8 h-7 w-48 animate-pulse rounded-xl bg-card" />
          <div className="grid gap-5 sm:grid-cols-3">
            {[0, 1, 2].map((i) => (
              <div key={i} className="rounded-2xl border border-border bg-card p-6">
                <div className="mb-1 h-3 w-24 animate-pulse rounded-full bg-cardAlt" />
                <div className="mb-2 h-5 w-32 animate-pulse rounded-lg bg-cardAlt" />
                <div className="mb-5 h-3 w-full animate-pulse rounded-full bg-cardAlt" />
                <div className="h-11 w-36 animate-pulse rounded-2xl bg-cardAlt" />
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* Metodoloji notu */}
      <section>
        <div className="mx-auto w-full max-w-6xl px-4 py-14 sm:px-6 lg:px-8">
          <div className="mb-6 h-7 w-52 animate-pulse rounded-xl bg-card" />
          <div className="rounded-2xl border border-border bg-card p-7">
            <div className="grid gap-6 sm:grid-cols-2 lg:grid-cols-4">
              {[0, 1, 2, 3].map((i) => (
                <div key={i}>
                  <div className="mb-1.5 h-4 w-24 animate-pulse rounded-lg bg-cardAlt" />
                  <div className="h-3 w-full animate-pulse rounded-full bg-cardAlt" />
                  <div className="mt-1.5 h-3 w-3/4 animate-pulse rounded-full bg-cardAlt" />
                </div>
              ))}
            </div>
          </div>
        </div>
      </section>
    </div>
  );
}
