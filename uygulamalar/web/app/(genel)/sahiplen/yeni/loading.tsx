// sahiplen/yeni/page.tsx + yeni-isletme-formu.tsx (Yeni İşletme Başvurusu) için tasarlandı — breadcrumb,
// başlık bloğu ve tek kart içindeki başvuru formunun (ad/kategori/şehir-ilçe/adres/telefon-web/buton) şeklini izler.
export default function SahiplenYeniLoading() {
  return (
    <main className="mx-auto max-w-xl px-4 py-10 sm:px-6">
      {/* Breadcrumb */}
      <div className="mb-2 h-3 w-32 animate-pulse rounded bg-cardAlt" />

      {/* Başlık */}
      <div className="mb-8 space-y-2">
        <div className="h-3 w-40 animate-pulse rounded-lg bg-card" />
        <div className="h-8 w-64 animate-pulse rounded-xl bg-card" />
        <div className="h-4 w-full max-w-md animate-pulse rounded-lg bg-card" />
        <div className="h-4 w-2/3 max-w-sm animate-pulse rounded-lg bg-card" />
      </div>

      {/* Başvuru formu kartı */}
      <div className="overflow-hidden rounded-2xl border border-border bg-bg">
        <div className="space-y-4 p-5">
          {/* İşletme adı */}
          <div className="flex flex-col gap-1.5">
            <div className="h-3 w-24 animate-pulse rounded bg-cardAlt" />
            <div className="h-11 animate-pulse rounded-xl border border-border bg-bg" />
          </div>
          {/* Kategori */}
          <div className="flex flex-col gap-1.5">
            <div className="h-3 w-20 animate-pulse rounded bg-cardAlt" />
            <div className="h-11 animate-pulse rounded-xl border border-border bg-bg" />
          </div>
          {/* Şehir + İlçe */}
          <div className="grid grid-cols-2 gap-3">
            <div className="flex flex-col gap-1.5">
              <div className="h-3 w-14 animate-pulse rounded bg-cardAlt" />
              <div className="h-11 animate-pulse rounded-xl border border-border bg-bg" />
            </div>
            <div className="flex flex-col gap-1.5">
              <div className="h-3 w-14 animate-pulse rounded bg-cardAlt" />
              <div className="h-11 animate-pulse rounded-xl border border-border bg-bg" />
            </div>
          </div>
          {/* Adres */}
          <div className="flex flex-col gap-1.5">
            <div className="h-3 w-16 animate-pulse rounded bg-cardAlt" />
            <div className="h-16 animate-pulse rounded-xl border border-border bg-bg" />
          </div>
          {/* Telefon + Web */}
          <div className="grid grid-cols-2 gap-3">
            <div className="flex flex-col gap-1.5">
              <div className="h-3 w-16 animate-pulse rounded bg-cardAlt" />
              <div className="h-11 animate-pulse rounded-xl border border-border bg-bg" />
            </div>
            <div className="flex flex-col gap-1.5">
              <div className="h-3 w-20 animate-pulse rounded bg-cardAlt" />
              <div className="h-11 animate-pulse rounded-xl border border-border bg-bg" />
            </div>
          </div>
          {/* Süreç bilgisi */}
          <div className="h-14 animate-pulse rounded-xl border border-blue-100 bg-blue-50" />
          {/* Gönder butonu */}
          <div className="h-12 w-full animate-pulse rounded-xl bg-cardAlt" />
        </div>
      </div>
    </main>
  );
}
