// destek/page.tsx (SSS/akordeon destek sayfası) için tasarlandı — başlık bloğu +
// birden çok "bölüm başlığı + akordeon satırları" kartı + alt kısımda destek iletişim kartı.
export default function DestekLoading() {
  return (
    <main className="min-h-screen bg-bg py-12">
      <div className="mx-auto max-w-3xl px-4 sm:px-6 lg:px-8">
        {/* Başlık */}
        <div className="mb-10 space-y-2">
          <div className="h-3 w-16 animate-pulse rounded-lg bg-card" />
          <div className="h-8 w-64 animate-pulse rounded-xl bg-card sm:h-9" />
          <div className="h-4 w-80 max-w-full animate-pulse rounded-lg bg-card" />
        </div>

        {/* SSS bölümleri */}
        <div className="space-y-8">
          {[0, 1, 2, 3, 4].map((section) => (
            <div key={section}>
              <div className="mb-4 h-5 w-40 animate-pulse rounded-lg bg-card" />
              <div className="divide-y divide-border overflow-hidden rounded-[24px] border border-border bg-card">
                {[0, 1, 2].map((row) => (
                  <div key={row} className="flex items-center justify-between gap-4 px-5 py-4">
                    <div className="h-4 w-2/3 animate-pulse rounded-lg bg-cardAlt" />
                    <div className="h-4 w-4 shrink-0 animate-pulse rounded-full bg-cardAlt" />
                  </div>
                ))}
              </div>
            </div>
          ))}
        </div>

        {/* Destek iletişim kartı */}
        <div className="mt-12 rounded-[24px] border border-border bg-cardAlt p-8 text-center">
          <div className="mx-auto mb-4 h-12 w-12 animate-pulse rounded-2xl bg-card" />
          <div className="mx-auto mb-2 h-4 w-48 animate-pulse rounded-lg bg-card" />
          <div className="mx-auto mb-5 h-4 w-64 max-w-full animate-pulse rounded-lg bg-card" />
          <div className="mx-auto h-11 w-52 animate-pulse rounded-2xl bg-card" />
        </div>
      </div>
    </main>
  );
}
