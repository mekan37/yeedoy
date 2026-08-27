// yasal/page.tsx (yasal belge listesi) için tasarlandı — başlık + tıklanabilir belge
// satırlarından oluşan basit bir liste. Next.js bu iskeleti hem /yasal hem /yasal/[slug] için
// kullanır (ikisinin şekli çok farklı olduğundan [slug] altında ayrıca daha spesifik bir
// loading.tsx da var — bkz. yasal/[slug]/loading.tsx).
export default function YasalLoading() {
  return (
    <main className="min-h-screen bg-bg">
      <div className="mx-auto max-w-2xl px-4 py-12">
        <div className="mb-2 h-8 w-56 animate-pulse rounded-xl bg-card" />
        <div className="mb-8 h-4 w-64 max-w-full animate-pulse rounded-lg bg-card" />

        <div className="flex flex-col gap-4">
          {[0, 1, 2, 3].map((row) => (
            <div
              key={row}
              className="flex items-center justify-between rounded-2xl border border-border bg-card px-6 py-5"
            >
              <div className="space-y-2">
                <div className="h-4 w-40 animate-pulse rounded-lg bg-cardAlt" />
                <div className="h-3.5 w-56 max-w-full animate-pulse rounded-lg bg-cardAlt" />
              </div>
              <div className="h-4 w-4 shrink-0 animate-pulse rounded-full bg-cardAlt" />
            </div>
          ))}
        </div>
      </div>
    </main>
  );
}
