// gomulu/izle/page.tsx (URL parametresiyle gelen video/web embed görüntüleyici) için
// tasarlandı — geri linki + başlık + embed'in kendi "tarayıcı çubuğu + iframe" kartının şeklini
// izleyen tek bir kart.
export default function GomoluIzleLoading() {
  return (
    <main className="min-h-screen bg-bg">
      <div className="mx-auto max-w-4xl px-4 py-8">
        <div className="mb-6 h-4 w-28 animate-pulse rounded-lg bg-card" />
        <div className="mb-6 h-7 w-44 animate-pulse rounded-xl bg-card" />

        <div className="overflow-hidden rounded-2xl border border-border bg-card shadow-yd1">
          <div className="flex min-h-[52px] items-center gap-3 border-b border-border px-4">
            <div className="h-2.5 w-2.5 shrink-0 animate-pulse rounded-full bg-cardAlt" />
            <div className="h-2.5 w-2.5 shrink-0 animate-pulse rounded-full bg-cardAlt" />
            <div className="h-2.5 w-2.5 shrink-0 animate-pulse rounded-full bg-cardAlt" />
            <div className="ml-2 h-3.5 w-40 max-w-[60%] animate-pulse rounded-lg bg-cardAlt" />
            <div className="ml-auto h-3.5 w-24 shrink-0 animate-pulse rounded-lg bg-cardAlt" />
          </div>
          <div className="h-[70vh] w-full animate-pulse bg-cardAlt" />
        </div>
      </div>
    </main>
  );
}
