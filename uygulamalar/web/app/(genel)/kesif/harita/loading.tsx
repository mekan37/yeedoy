// kesif/harita/page.tsx (tam ekran harita görünümü) için tasarlandı — PublicShell içindeki
// header altında kalan tüm alanı kaplayan yuvarlak köşeli harita placeholder'ı, üzerinde sol
// üstte arama kutusu ve altında kategori filtre çipleri satırı (bkz. harita-istemcisi.tsx'teki
// HaritaArama ve HARITA_KATEGORILERI şeridi).
export default function HaritaLoading() {
  return (
    <div style={{ height: 'calc(100vh - 64px)' }} className="relative overflow-hidden bg-cardAlt">
      {/* Harita zemini */}
      <div className="absolute inset-0 animate-pulse bg-cardAlt" />

      {/* Arama kutusu */}
      <div className="absolute left-2.5 top-2.5 z-10 h-11 w-[280px] max-w-[70%] animate-pulse rounded-[10px] bg-card shadow-yd2" />

      {/* Kategori filtre çipleri */}
      <div className="absolute inset-x-3 top-16 z-10 flex flex-wrap gap-2">
        {Array.from({ length: 6 }).map((_, i) => (
          <div key={i} className="h-8 w-24 animate-pulse rounded-full bg-card shadow-yd1" />
        ))}
      </div>
    </div>
  );
}
