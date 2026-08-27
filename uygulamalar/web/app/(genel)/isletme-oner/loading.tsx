// isletme-oner/isletme-oner-formu.tsx (İşletme Öner formu) için tasarlandı — başlık satırı +
// sol sabit bilgi kartları + sağ tarafta gerçek form alanlarının (ad/kategori, şehir/ilçe, adres,
// harita, telefon/web, açıklama, dosya yükleme, onay kutuları, butonlar) şeklini izleyen kart.
export default function IsletmeOnerLoading() {
  return (
    <div className="mx-auto max-w-7xl px-4 py-8 sm:px-6">
      {/* Başlık */}
      <div className="mb-6 flex flex-wrap items-start justify-between gap-4">
        <div className="space-y-2">
          <div className="h-8 w-48 animate-pulse rounded-xl bg-card sm:h-9" />
          <div className="h-4 w-64 max-w-full animate-pulse rounded-lg bg-card" />
        </div>
        <div className="h-10 w-64 shrink-0 animate-pulse rounded-xl bg-card" />
      </div>

      <div className="flex flex-col gap-6 lg:flex-row lg:items-start">
        {/* Sol sidebar */}
        <aside className="w-full space-y-4 lg:w-72 lg:shrink-0">
          <div className="h-64 animate-pulse rounded-2xl border border-border bg-card shadow-yd1" />
          <div className="h-24 animate-pulse rounded-2xl border border-amber-200 bg-amber-50" />
        </aside>

        {/* Sağ: form kartı */}
        <div className="min-w-0 flex-1">
          <div className="rounded-2xl border border-border bg-card p-6 shadow-yd1">
            <div className="mb-5 h-5 w-40 animate-pulse rounded-lg bg-cardAlt" />
            <div className="grid gap-4">
              {/* Ad + Kategori */}
              <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
                <div className="h-11 animate-pulse rounded-xl bg-cardAlt" />
                <div className="h-11 animate-pulse rounded-xl bg-cardAlt" />
              </div>
              {/* Şehir + İlçe */}
              <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
                <div className="h-11 animate-pulse rounded-xl bg-cardAlt" />
                <div className="h-11 animate-pulse rounded-xl bg-cardAlt" />
              </div>
              {/* Mahalle */}
              <div className="h-11 animate-pulse rounded-xl bg-cardAlt" />
              {/* Adres */}
              <div className="h-11 animate-pulse rounded-xl bg-cardAlt" />
              {/* Harita */}
              <div className="h-40 animate-pulse rounded-xl bg-cardAlt" />
              {/* Telefon + Web */}
              <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
                <div className="h-11 animate-pulse rounded-xl bg-cardAlt" />
                <div className="h-11 animate-pulse rounded-xl bg-cardAlt" />
              </div>
              {/* Sosyal + Neden */}
              <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
                <div className="h-11 animate-pulse rounded-xl bg-cardAlt" />
                <div className="h-11 animate-pulse rounded-xl bg-cardAlt" />
              </div>
              {/* Ek açıklama */}
              <div className="h-24 animate-pulse rounded-xl bg-cardAlt" />
              {/* Fotoğraf yükleme */}
              <div className="h-24 animate-pulse rounded-xl border-2 border-dashed border-border bg-bg" />
              {/* Onaylar */}
              <div className="space-y-3 border-t border-border pt-4">
                <div className="h-4 w-64 max-w-full animate-pulse rounded-lg bg-cardAlt" />
                <div className="h-4 w-56 max-w-full animate-pulse rounded-lg bg-cardAlt" />
              </div>
              {/* Butonlar */}
              <div className="flex flex-col gap-3 sm:flex-row">
                <div className="h-12 flex-1 animate-pulse rounded-xl bg-cardAlt" />
                <div className="h-12 flex-2 animate-pulse rounded-xl bg-cardAlt" />
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
