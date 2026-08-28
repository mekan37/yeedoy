// [sehir]/[slug]/page.tsx (SehirSlugPage — ilçe VEYA kategori moduna göre işletme listesi;
// hangi mod olduğu istekten önce bilinmez, ikisi de aynı grid çatısını paylaşır) için tasarlandı.
// [sehir]/loading.tsx'teki breadcrumb+başlık desenini izler, ardından isletme-karti.tsx'teki
// BusinessTile şeklinde (ikon kutusu + başlık/alt satır) kart grid'ini gösterir.
export default function SehirSlugLoading() {
  return (
    <main className="min-h-screen bg-bg">
      <div className="mx-auto w-full max-w-6xl px-4 py-8 sm:px-6 lg:px-8">
        {/* Breadcrumb */}
        <div className="mb-4 flex items-center gap-2">
          <div className="h-4 w-16 animate-pulse rounded-lg bg-card" />
          <div className="h-4 w-3 animate-pulse rounded-lg bg-card" />
          <div className="h-4 w-20 animate-pulse rounded-lg bg-card" />
          <div className="h-4 w-3 animate-pulse rounded-lg bg-card" />
          <div className="h-4 w-24 animate-pulse rounded-lg bg-card" />
        </div>

        {/* Başlık + alt satır */}
        <div className="mb-8 space-y-2">
          <div className="h-8 w-64 max-w-full animate-pulse rounded-xl bg-card" />
          <div className="h-4 w-40 animate-pulse rounded-lg bg-card" />
        </div>

        {/* İşletme/kategori kartları grid'i */}
        <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-3">
          {Array.from({ length: 9 }).map((_, i) => (
            <div key={i} className="flex items-center gap-3 rounded-[20px] border border-border bg-cardAlt p-3 shadow-yd2">
              <div className="h-16 w-16 shrink-0 animate-pulse rounded-[18px] bg-card" />
              <div className="min-w-0 flex-1 space-y-2">
                <div className="h-4 w-3/4 animate-pulse rounded-lg bg-card" />
                <div className="h-3 w-1/2 animate-pulse rounded-lg bg-card" />
                <div className="h-3 w-1/3 animate-pulse rounded-lg bg-card" />
              </div>
            </div>
          ))}
        </div>
      </div>
    </main>
  );
}
