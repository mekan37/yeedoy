// yasal/[slug]/page.tsx (tek bir yasal belge — geri linki + başlık + markdown gövdesi) için
// tasarlandı. Üstteki yasal/loading.tsx'in liste şekli buraya uymadığı için ayrı bir iskelet.
export default function YasalDetayLoading() {
  return (
    <main className="min-h-screen bg-bg">
      <div className="mx-auto max-w-3xl px-4 py-12">
        <div className="mb-8 h-4 w-40 animate-pulse rounded-lg bg-card" />

        <div className="mb-8 h-8 w-72 max-w-full animate-pulse rounded-xl bg-card" />

        <div className="space-y-6">
          {[0, 1, 2, 3].map((section) => (
            <div key={section} className="space-y-2">
              <div className="h-4 w-48 animate-pulse rounded-lg bg-card" />
              <div className="h-3.5 w-full animate-pulse rounded-lg bg-card" />
              <div className="h-3.5 w-11/12 animate-pulse rounded-lg bg-card" />
              <div className="h-3.5 w-4/5 animate-pulse rounded-lg bg-card" />
            </div>
          ))}
        </div>

        <div className="mt-12 border-t border-border pt-8">
          <div className="h-3.5 w-56 animate-pulse rounded-lg bg-card" />
        </div>
      </div>
    </main>
  );
}
