// isletme/page.tsx (işletme sahiplerine yönelik pazarlama/landing sayfası) için tasarlandı —
// hero (eyebrow + başlık + alt metin + iki CTA) + özellik kartları grid'i + 3 adımlı "nasıl
// çalışır" bölümü + iletişim formu kartının şeklini izler.
export default function IsletmeLandingLoading() {
  return (
    <main className="min-h-screen bg-bg">
      {/* Hero */}
      <section className="mx-auto max-w-4xl px-5 pb-16 pt-20 text-center sm:pt-28">
        <div className="mx-auto h-6 w-32 animate-pulse rounded-full bg-card" />
        <div className="mx-auto mt-5 h-10 w-full max-w-xl animate-pulse rounded-xl bg-card sm:h-12" />
        <div className="mx-auto mt-3 h-10 w-3/4 max-w-md animate-pulse rounded-xl bg-card sm:h-12" />
        <div className="mx-auto mt-5 h-4 w-full max-w-2xl animate-pulse rounded-lg bg-card" />
        <div className="mx-auto mt-2 h-4 w-2/3 max-w-xl animate-pulse rounded-lg bg-card" />
        <div className="mt-8 flex flex-wrap justify-center gap-3">
          <div className="h-12 w-40 animate-pulse rounded-2xl bg-card" />
          <div className="h-12 w-36 animate-pulse rounded-2xl bg-card" />
        </div>
      </section>

      {/* Özellikler */}
      <section className="border-t border-border bg-card py-16">
        <div className="mx-auto max-w-5xl px-5">
          <div className="mx-auto h-7 w-72 max-w-full animate-pulse rounded-xl bg-bg" />
          <div className="mt-10 grid gap-5 sm:grid-cols-2 lg:grid-cols-3">
            {Array.from({ length: 6 }).map((_, i) => (
              <div key={i} className="rounded-2xl border border-border bg-bg p-5">
                <div className="h-7 w-7 animate-pulse rounded-lg bg-card" />
                <div className="mt-3 h-4 w-32 animate-pulse rounded-lg bg-card" />
                <div className="mt-1.5 h-3.5 w-full animate-pulse rounded-lg bg-card" />
                <div className="mt-1 h-3.5 w-4/5 animate-pulse rounded-lg bg-card" />
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* Nasıl çalışır */}
      <section className="py-16">
        <div className="mx-auto max-w-3xl px-5 text-center">
          <div className="mx-auto h-7 w-56 animate-pulse rounded-xl bg-card" />
          <div className="mt-10 grid gap-5 sm:grid-cols-3">
            {Array.from({ length: 3 }).map((_, i) => (
              <div key={i} className="rounded-2xl border border-border bg-bg p-6">
                <div className="mx-auto h-8 w-10 animate-pulse rounded-lg bg-card sm:mx-0" />
                <div className="mx-auto mt-2 h-4 w-28 animate-pulse rounded-lg bg-card sm:mx-0" />
                <div className="mx-auto mt-1.5 h-3.5 w-full animate-pulse rounded-lg bg-card sm:mx-0" />
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* İletişim */}
      <section className="border-t border-border bg-card py-16">
        <div className="mx-auto max-w-2xl px-5 text-center">
          <div className="mx-auto h-7 w-52 animate-pulse rounded-xl bg-bg" />
          <div className="mx-auto mt-3 h-4 w-72 max-w-full animate-pulse rounded-lg bg-bg" />
          <div className="mx-auto mt-8 h-64 animate-pulse rounded-2xl border border-border bg-bg" />
        </div>
      </section>
    </main>
  );
}
