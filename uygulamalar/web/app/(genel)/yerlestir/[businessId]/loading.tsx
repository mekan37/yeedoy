// yerlestir/[businessId]/page.tsx (EmbedViewerPage — bir işletmenin harici sitelere gömülen
// kompakt menü widget'ı) için tasarlandı: logo+isim başlığı, açıklama satırları, menü linkleri
// listesi ve alt "Yeedoy'da gör" satırının şeklini izler.
export default function YerlestirLoading() {
  return (
    <div className="w-full max-w-sm bg-card p-4">
      {/* İşletme başlığı */}
      <div className="mb-4 flex items-center gap-3">
        <div className="h-12 w-12 shrink-0 animate-pulse rounded-xl bg-cardAlt" />
        <div className="flex-1 space-y-1.5">
          <div className="h-4 w-32 animate-pulse rounded-lg bg-cardAlt" />
          <div className="h-3 w-24 animate-pulse rounded-lg bg-cardAlt" />
        </div>
      </div>

      {/* Açıklama */}
      <div className="mb-4 space-y-1.5">
        <div className="h-3 w-full animate-pulse rounded-lg bg-cardAlt" />
        <div className="h-3 w-2/3 animate-pulse rounded-lg bg-cardAlt" />
      </div>

      {/* Menü listesi */}
      <div className="mb-2 h-3 w-16 animate-pulse rounded-lg bg-cardAlt" />
      <div className="flex flex-col gap-2">
        <div className="h-10 w-full animate-pulse rounded-xl border border-border bg-bg" />
        <div className="h-10 w-full animate-pulse rounded-xl border border-border bg-bg" />
        <div className="h-10 w-full animate-pulse rounded-xl border border-border bg-bg" />
      </div>

      {/* Alt bağlantı */}
      <div className="mt-4 flex justify-end border-t border-border pt-3">
        <div className="h-3 w-24 animate-pulse rounded-lg bg-cardAlt" />
      </div>
    </div>
  );
}
