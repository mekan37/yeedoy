// sahiplen/page.tsx (ClaimPage — sahiplenme giriş sayfası) için tasarlandı — bg-cardAlt hero bandı
// (başlık + buton çifti + sağda bilgi kartı) ve altında 3 adımlık kart grid'inin şeklini izler.
export default function SahiplenLoading() {
  return (
    <main>
      {/* Hero bandı */}
      <section className="border-b border-border bg-cardAlt py-12">
        <div className="mx-auto grid w-full max-w-6xl gap-8 px-4 sm:px-6 lg:grid-cols-[1fr_360px] lg:items-center lg:px-8">
          <div className="space-y-4">
            <div className="h-3 w-24 animate-pulse rounded-lg bg-card" />
            <div className="space-y-2">
              <div className="h-9 w-full max-w-xl animate-pulse rounded-xl bg-card sm:h-11" />
              <div className="h-9 w-2/3 max-w-md animate-pulse rounded-xl bg-card sm:h-11" />
            </div>
            <div className="space-y-2">
              <div className="h-4 w-full max-w-lg animate-pulse rounded-lg bg-card" />
              <div className="h-4 w-3/4 max-w-md animate-pulse rounded-lg bg-card" />
            </div>
            <div className="mt-7 flex flex-wrap gap-2">
              <div className="h-11 w-40 animate-pulse rounded-xl bg-card" />
              <div className="h-11 w-36 animate-pulse rounded-xl bg-card" />
            </div>
          </div>
          <div className="rounded-[20px] border border-border bg-card p-5 shadow-yd1">
            <div className="h-6 w-44 animate-pulse rounded-full bg-cardAlt" />
            <div className="mt-5 grid gap-4">
              {[0, 1, 2, 3].map((row) => (
                <div key={row} className="h-11 animate-pulse rounded-2xl bg-cardAlt" />
              ))}
            </div>
          </div>
        </div>
      </section>

      {/* 3 adım kartları */}
      <div className="mx-auto grid w-full max-w-6xl gap-5 px-4 py-10 sm:px-6 md:grid-cols-3 lg:px-8">
        {[0, 1, 2].map((card) => (
          <div key={card} className="rounded-[20px] border border-border bg-card p-5 shadow-yd1">
            <div className="h-5 w-32 animate-pulse rounded-lg bg-cardAlt" />
            <div className="mt-3 space-y-2">
              <div className="h-3.5 w-full animate-pulse rounded-lg bg-cardAlt" />
              <div className="h-3.5 w-4/5 animate-pulse rounded-lg bg-cardAlt" />
            </div>
          </div>
        ))}
      </div>

      {/* Giriş linki */}
      <div className="mx-auto w-full max-w-6xl px-4 pb-10 sm:px-6 lg:px-8">
        <div className="h-4 w-48 animate-pulse rounded-lg bg-cardAlt" />
      </div>
    </main>
  );
}
