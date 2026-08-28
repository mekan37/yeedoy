// yorum-politikasi/page.tsx (tek bir yasal belge — geri linki + başlık + numaralı madde
// bölümleri) için tasarlandı. yasal/[slug]/loading.tsx ile aynı belge-detay şeklini izler,
// çünkü bu sayfa da aynı "geri link + başlık + metin blokları" yerleşimini kullanıyor.
export default function YorumPolitikasiLoading() {
  return (
    <main className="min-h-screen bg-bg">
      <div className="mx-auto max-w-3xl px-4 py-12">
        <div className="mb-8 h-4 w-40 animate-pulse rounded-lg bg-card" />

        <div className="mb-3 h-8 w-72 max-w-full animate-pulse rounded-xl bg-card" />
        <div className="mb-8 h-4 w-40 animate-pulse rounded-lg bg-card" />

        <div className="space-y-8">
          {Array.from({ length: 8 }).map((_, section) => (
            <div key={section} className="space-y-2">
              <div className="h-4 w-48 animate-pulse rounded-lg bg-card" />
              <div className="h-3.5 w-full animate-pulse rounded-lg bg-card" />
              <div className="h-3.5 w-11/12 animate-pulse rounded-lg bg-card" />
              <div className="h-3.5 w-4/5 animate-pulse rounded-lg bg-card" />
            </div>
          ))}
        </div>

        <div className="mt-12 flex flex-wrap gap-4 border-t border-border pt-8">
          <div className="h-4 w-32 animate-pulse rounded-lg bg-card" />
          <div className="h-4 w-36 animate-pulse rounded-lg bg-card" />
          <div className="h-4 w-40 animate-pulse rounded-lg bg-card" />
        </div>
      </div>
    </main>
  );
}
