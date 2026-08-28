// oyoyla/[token]/page.tsx (OyVerPage) + oy-verme-yuzeyi.tsx (OyVermeYuzeyi) için tasarlandı:
// ortalanmış eyebrow/başlık satırları + "önde gelen" banner'ı + oy kartları listesinin (başlık/alt
// satır/skor kutusu + iki oy butonu) şeklini izler.
export default function OyVerLoading() {
  return (
    <main className="min-h-screen bg-bg px-4 py-10">
      <div className="mx-auto max-w-lg">
        {/* Başlık */}
        <div className="mb-6 flex flex-col items-center gap-2 text-center">
          <div className="h-3 w-24 animate-pulse rounded-lg bg-card" />
          <div className="h-7 w-48 max-w-full animate-pulse rounded-xl bg-card" />
          <div className="h-4 w-56 max-w-full animate-pulse rounded-lg bg-card" />
        </div>

        <div className="flex flex-col gap-4">
          {/* Önde gelen banner */}
          <div className="rounded-2xl border border-border bg-cardAlt px-4 py-3 text-center">
            <div className="mx-auto mb-2 h-3 w-32 animate-pulse rounded-lg bg-card" />
            <div className="mx-auto mb-1 h-5 w-40 animate-pulse rounded-lg bg-card" />
            <div className="mx-auto h-3 w-28 animate-pulse rounded-lg bg-card" />
          </div>

          {/* Oy kartları */}
          {[0, 1, 2].map((i) => (
            <div key={i} className="rounded-2xl border border-border bg-card p-4">
              <div className="flex items-start justify-between gap-3">
                <div className="flex-1 space-y-2">
                  <div className="h-4 w-40 max-w-full animate-pulse rounded-lg bg-cardAlt" />
                  <div className="h-3 w-28 animate-pulse rounded-lg bg-cardAlt" />
                  <div className="h-3 w-20 animate-pulse rounded-lg bg-cardAlt" />
                </div>
                <div className="shrink-0 space-y-1 text-center">
                  <div className="h-5 w-8 animate-pulse rounded-lg bg-cardAlt" />
                  <div className="h-2.5 w-12 animate-pulse rounded-lg bg-cardAlt" />
                </div>
              </div>
              <div className="mt-3 flex gap-2">
                <div className="h-10 flex-1 animate-pulse rounded-xl bg-cardAlt" />
                <div className="h-10 flex-1 animate-pulse rounded-xl bg-cardAlt" />
              </div>
            </div>
          ))}
        </div>

        {/* Alt bilgi */}
        <div className="mx-auto mt-4 h-3 w-64 max-w-full animate-pulse rounded-lg bg-card" />
      </div>
    </main>
  );
}
