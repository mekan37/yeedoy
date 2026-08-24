/**
 * Sahip görsel yüklemediyse gösterilecek stok yemek fotoğrafını bulur.
 * Kaynak: DB-tabanlı `stock_dish_images` kütüphanesi (get_stock_dish_images_v1
 * RPC'siyle çekilir, bkz. stok-yemek-kutuphanesi.ts) — admin panelinden
 * (`/yonetici/gorsel-kutuphanesi`) yönetilir. Eskiden kod içine gömülü statik
 * bir sözlüktü, artık salt eşleştirme algoritması burada, veri kütüphaneden
 * gelir.
 */

export type StockDishImage = { id: string; image_url: string; keywords: string[] };

// Türkçe karakterleri sadeleştirip tüm boşluk/noktalama işaretlerini siler —
// "Karnıyarık", "karni_yarik" ve "Karnı Yarık" hepsi "karniyarik" olur, böylece
// hem admin'in girdiği anahtar ifade hem sahibin yazım biçimi (bitişik/ayrık)
// eşleşmeyi bozmaz.
function normalizeTr(s: string): string {
  return s
    .toLocaleLowerCase('tr')
    .replace(/ç/g, 'c')
    .replace(/ğ/g, 'g')
    .replace(/ı/g, 'i')
    .replace(/ö/g, 'o')
    .replace(/ş/g, 's')
    .replace(/ü/g, 'u')
    .replace(/[^a-z0-9]+/g, '');
}

/**
 * Ürün adına eşleşen tüm stok görselleri, en uzun/özgül anahtar ifadeden en
 * genele doğru sıralı döner. Owner-facing "Sistemden Seç" adayları için.
 */
export function bulEslesenYemekGorselleri(urunAdi: string, library: StockDishImage[]): StockDishImage[] {
  const n = normalizeTr(urunAdi);
  if (!n) return [];

  const scored: Array<{ item: StockDishImage; len: number }> = [];
  for (const item of library) {
    let bestLen = 0;
    for (const kw of item.keywords) {
      const nk = normalizeTr(kw);
      if (nk && n.includes(nk) && nk.length > bestLen) bestLen = nk.length;
    }
    if (bestLen > 0) scored.push({ item, len: bestLen });
  }
  scored.sort((a, b) => b.len - a.len);
  return scored.map((s) => s.item);
}

/**
 * Otomatik sessiz fallback için tek (en iyi) eşleşmenin image_url'ini döner,
 * eşleşme yoksa null (çağıran taraf mevcut jenerik ikon/emoji fallback'ine
 * düşmeli).
 */
export function bulVarsayilanYemekGorseli(urunAdi: string, library: StockDishImage[]): string | null {
  return bulEslesenYemekGorselleri(urunAdi, library)[0]?.image_url ?? null;
}
