// (genel)/loading.tsx menü sayfası (hero+filtre çubuğu+menü grid) için tasarlanmıştı —
// /oneri artık kişiye özel veri yüzünden her ziyarette taze render alıyor (revalidate=0),
// bu yüzden o yanlış şekilli iskelet burada sürekli görünür hale geldi. Bu, oneri-canli.tsx'in
// gerçek yerleşimini (başlık satırı + sol sidebar kartları + sağ karusel bölümleri) yansıtır.
export default function OneriLoading() {
  return (
    <main className="min-h-screen bg-bg">
      <div className="mx-auto max-w-7xl px-4 py-8 sm:px-6">
        {/* Başlık */}
        <div className="mb-8 flex items-start justify-between gap-4">
          <div className="space-y-2">
            <div className="h-8 w-48 animate-pulse rounded-xl bg-card" />
            <div className="h-4 w-64 animate-pulse rounded-lg bg-card" />
          </div>
          <div className="h-10 w-40 shrink-0 animate-pulse rounded-xl bg-card" />
        </div>

        <div className="flex flex-col gap-8 lg:flex-row lg:items-start">
          {/* Sol sidebar */}
          <aside className="w-full space-y-5 lg:w-64 lg:shrink-0">
            <div className="h-40 animate-pulse rounded-2xl border border-border bg-card shadow-yd1" />
            <div className="h-40 animate-pulse rounded-2xl border border-border bg-card shadow-yd1" />
            <div className="h-28 animate-pulse rounded-2xl border border-border bg-card shadow-yd1" />
          </aside>

          {/* Sağ: karusel bölümleri */}
          <div className="min-w-0 flex-1 space-y-10">
            {[0, 1].map((bolum) => (
              <div key={bolum}>
                <div className="mb-4 h-6 w-56 animate-pulse rounded-lg bg-card" />
                <div className="flex gap-3 overflow-hidden">
                  {[0, 1, 2, 3].map((i) => (
                    <div key={i} className="h-[236px] w-[220px] shrink-0 animate-pulse rounded-2xl border border-border bg-card shadow-yd1" />
                  ))}
                </div>
              </div>
            ))}

            <div className="grid grid-cols-2 gap-3 sm:grid-cols-4">
              {[0, 1, 2, 3].map((i) => (
                <div key={i} className="h-24 animate-pulse rounded-2xl border border-border bg-card shadow-yd1" />
              ))}
            </div>
          </div>
        </div>
      </div>
    </main>
  );
}
