// zincir/[slug]/page.tsx için özel iskelet: başlık bloğu (eyebrow + zincir adı +
// açıklama + şube sayısı) ve get_chain_overview_v2 sonucundan gelen şube kartları
// listesini (isim + şube etiketi, ilçe/şehir, adres, açık/kapalı rozeti, fiyat farkı)
// yansıtır.
export default function ZincirLoading() {
  return (
    <div className="min-h-screen bg-bg">
      <div className="mx-auto max-w-3xl px-4 py-8">
        {/* Başlık */}
        <div className="mb-6">
          <div className="mb-1 h-3 w-24 animate-pulse rounded-full bg-card" />
          <div className="h-7 w-56 animate-pulse rounded-xl bg-card" />
          <div className="mt-2 h-3.5 w-full animate-pulse rounded-full bg-card" />
          <div className="mt-1 h-3.5 w-20 animate-pulse rounded-full bg-card" />
        </div>

        {/* Şube listesi */}
        <div className="flex flex-col gap-3">
          {[0, 1, 2, 3, 4].map((i) => (
            <div
              key={i}
              className="flex items-start justify-between gap-2 rounded-xl border border-border bg-card p-4"
            >
              <div className="min-w-0 flex-1 space-y-2">
                <div className="flex items-center gap-2">
                  <div className="h-4 w-36 animate-pulse rounded-lg bg-cardAlt" />
                  <div className="h-4 w-14 animate-pulse rounded-full bg-cardAlt" />
                </div>
                <div className="h-3 w-28 animate-pulse rounded-full bg-cardAlt" />
                <div className="h-3 w-40 animate-pulse rounded-full bg-cardAlt" />
              </div>
              <div className="flex shrink-0 flex-col items-end gap-1.5">
                <div className="h-4 w-12 animate-pulse rounded-full bg-cardAlt" />
                <div className="h-3 w-16 animate-pulse rounded-full bg-cardAlt" />
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}
