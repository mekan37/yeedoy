// sahiplen/talep/page.tsx + talep-formu.tsx (Sahiplenme Talebi formu) için tasarlandı — ortalanmış
// başlık, seçilen işletme özet kartı ve altındaki talep formunun (ad/telefon/dosya/not/buton) şeklini izler.
export default function SahiplenTalepLoading() {
  return (
    <main className="mx-auto max-w-xl px-4 py-10 sm:px-6">
      {/* Başlık */}
      <div className="mb-8 flex flex-col items-center space-y-2 text-center">
        <div className="h-3 w-20 animate-pulse rounded-lg bg-card" />
        <div className="h-8 w-52 animate-pulse rounded-xl bg-card" />
      </div>

      {/* İşletme özet kartı */}
      <div className="mb-6 overflow-hidden rounded-2xl border border-border bg-bg">
        <div className="flex items-center gap-3 border-b border-border bg-primary/5 px-4 py-3">
          <div className="h-10 w-10 shrink-0 animate-pulse rounded-full bg-cardAlt" />
          <div className="min-w-0 flex-1 space-y-1.5">
            <div className="h-4 w-40 animate-pulse rounded bg-cardAlt" />
            <div className="h-3 w-56 max-w-full animate-pulse rounded bg-cardAlt" />
          </div>
        </div>
        <div className="space-y-1.5 px-4 py-3">
          <div className="h-3 w-48 animate-pulse rounded bg-cardAlt" />
          <div className="h-3 w-24 animate-pulse rounded bg-cardAlt" />
        </div>
      </div>

      {/* Talep formu */}
      <div className="space-y-4">
        {/* Ad Soyad */}
        <div className="flex flex-col gap-1.5">
          <div className="h-3 w-20 animate-pulse rounded bg-cardAlt" />
          <div className="h-11 animate-pulse rounded-xl border border-border bg-bg" />
        </div>
        {/* Telefon */}
        <div className="flex flex-col gap-1.5">
          <div className="h-3 w-16 animate-pulse rounded bg-cardAlt" />
          <div className="h-11 animate-pulse rounded-xl border border-border bg-bg" />
        </div>
        {/* Dosya yükleme */}
        <div className="flex flex-col gap-1.5">
          <div className="h-3 w-32 animate-pulse rounded bg-cardAlt" />
          <div className="h-3 w-64 max-w-full animate-pulse rounded bg-cardAlt" />
          <div className="h-16 animate-pulse rounded-xl border-2 border-dashed border-border bg-bg" />
        </div>
        {/* Ek not */}
        <div className="flex flex-col gap-1.5">
          <div className="h-3 w-20 animate-pulse rounded bg-cardAlt" />
          <div className="h-16 animate-pulse rounded-xl border border-border bg-bg" />
        </div>
        {/* Süreç bilgisi */}
        <div className="h-16 animate-pulse rounded-xl border border-amber-200 bg-amber-50" />
        {/* Gönder butonu */}
        <div className="h-12 w-full animate-pulse rounded-xl bg-cardAlt" />
      </div>
    </main>
  );
}
