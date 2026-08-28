// sahiplen/ara/page.tsx + isletme-arama-istemcisi.tsx (İşletmeni Bul arama sayfası) için tasarlandı —
// ortalanmış başlık bloğu ve altındaki 3 sütunlu (ad/şehir/ilçe) arama kutusu + ara butonunun şeklini izler.
export default function SahiplenAraLoading() {
  return (
    <main className="mx-auto max-w-2xl px-4 py-10 sm:px-6">
      {/* Başlık */}
      <div className="mb-8 flex flex-col items-center space-y-2 text-center">
        <div className="h-3 w-20 animate-pulse rounded-lg bg-card" />
        <div className="h-8 w-56 animate-pulse rounded-xl bg-card" />
        <div className="h-4 w-72 max-w-full animate-pulse rounded-lg bg-card" />
      </div>

      {/* Arama formu */}
      <div className="overflow-hidden rounded-2xl border border-border bg-bg shadow-xs">
        <div className="grid gap-0 divide-y divide-border sm:grid-cols-3 sm:divide-x sm:divide-y-0">
          {[0, 1, 2].map((col) => (
            <div key={col} className="flex flex-col gap-2 p-3">
              <div className="h-2.5 w-20 animate-pulse rounded bg-cardAlt" />
              <div className="h-4 w-28 animate-pulse rounded bg-cardAlt" />
            </div>
          ))}
        </div>
        <div className="border-t border-border px-3 py-2">
          <div className="h-9 w-20 animate-pulse rounded-xl bg-cardAlt" />
        </div>
      </div>
    </main>
  );
}
