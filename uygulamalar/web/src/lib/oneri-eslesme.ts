/**
 * Kullanıcının gerçek kategori tercih dağılımı (favorites/reviews/visits'ten,
 * get_my_category_preferences_v1 RPC'si) ve işletmenin gerçek ortalama puanından
 * deterministik bir %Uyum skoru hesaplar. Rastgelelik/hash yok — aynı girdi her
 * zaman aynı skoru üretir.
 */
export function eslesmeYuzdesiHesapla(
  category: string | null,
  preferences: Array<{ category: string; pct: number }>,
  avgRating: number | null,
): number {
  const taban = 70;
  const tercih = category ? preferences.find((p) => p.category === category) : undefined;
  const tercihBonusu = tercih ? Math.round(tercih.pct * 0.25) : 0;
  const puanBonusu = avgRating ? Math.round(((avgRating - 3) / 2) * 10) : 0;
  return Math.max(60, Math.min(99, taban + tercihBonusu + puanBonusu));
}
