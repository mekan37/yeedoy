// gizlilik/page.tsx (geri linki + başlık + çok sayıda madde/paragraf içeren uzun tek sütun
// yasal metin) için tasarlandı — yasal/[slug]/loading.tsx ile aynı aile ama sayfanın gerçek
// bölüm sayısına (6) yakın bir uzunlukta.
export default function GizlilikLoading() {
  return (
    <main className="min-h-screen bg-bg">
      <div className="mx-auto max-w-3xl px-4 py-12 sm:px-6 lg:px-8">
        <div className="mb-8 h-4 w-40 animate-pulse rounded-lg bg-card" />

        <div className="mb-2 h-8 w-64 max-w-full animate-pulse rounded-xl bg-card" />
        <div className="mb-10 h-3.5 w-36 animate-pulse rounded-lg bg-card" />

        <div className="space-y-7">
          {[0, 1, 2, 3, 4, 5].map((section) => (
            <div key={section} className="space-y-2">
              <div className="h-4 w-52 animate-pulse rounded-lg bg-card" />
              <div className="h-3.5 w-full animate-pulse rounded-lg bg-card" />
              <div className="h-3.5 w-full animate-pulse rounded-lg bg-card" />
              <div className="h-3.5 w-3/4 animate-pulse rounded-lg bg-card" />
            </div>
          ))}
        </div>

        <div className="my-8 border-t border-border" />
        <div className="h-3.5 w-72 max-w-full animate-pulse rounded-lg bg-card" />
      </div>
    </main>
  );
}
