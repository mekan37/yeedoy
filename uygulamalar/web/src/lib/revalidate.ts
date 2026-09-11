// Sayfa `revalidate` sürelerini adlandırılmış sabitler olarak tutar.
// Önceden aynı fikri temsil eden 6 farklı "sihirli sayı" (0/60/120/300/3600/86400)
// 20 dosyaya bağımsız olarak dağılmıştı — değerler burada DEĞİŞMEDİ (davranış
// aynı kalıyor), yalnızca anlamlı isimlere bağlandı.
export const REVALIDATE = {
  /** Kullanıcıya özel veya token bazlı içerik — her istekte taze. */
  REALTIME: 0,
  /** Sık değişen genel içerik (anasayfa). */
  SHORT: 60,
  /** Orta sıklıkta değişen alt sayfalar (yorumlar, harita, menü alt sayfaları). */
  MEDIUM: 120,
  /** İşletme/menü detay sayfaları, kampanyalar, liderler tablosu. */
  STANDARD: 300,
  /** Şehir/kategori listeleri, yasal doküman detayı. */
  LONG: 3600,
  /** Nadiren değişen statik içerik (yasal doküman index'i). */
  DAILY: 86400,
} as const;
