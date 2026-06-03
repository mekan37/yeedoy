/**
 * Fiyat seviyesi rozeti için tek eşik kaynağı.
 *
 * Mevcut durum (P0 — birleştirme):
 *   isletme-karti.tsx: <5000=₺  <15000=₺₺  ≥15000=₺₺₺  (çok düşük eşikler, eski)
 *   kesif.tsx (BusinessCard): <20000=₺  <45000=₺₺  ≥45000=₺₺₺
 *   kesif.tsx (BolgeselFiyatEndeksi): <15000=₺  <35000=₺₺  ≥35000=₺₺₺
 *
 * Seçilen eşikler: plan dosyasındaki öneriye ve kesif.tsx BusinessCard eşiklerine
 * göre hizalandı — bireysel işletme kartlarında daha gerçekçi Türkiye fiyat aralıkları.
 *
 * TODO(P2 migration): businesses.price_level sütunu + city+category bazlı p33/p66
 * percentile hesabı hazır olduğunda bu helper, DB sütununu tercihli kullanacak.
 * Bkz. docs/db-open-hours-price-badge-plan.md — Bölüm 4 ve 6.
 *
 * Eşikler enflasyon ile revize edilmeli — değişiklik için bu dosya tek nokta.
 */

/** medianPriceCents eşikleri (kuruş cinsinden). */
export const PRICE_LEVEL_THRESHOLDS = {
  /** medianPriceCents < BUDGET → ₺ (Ekonomik) */
  BUDGET: 20000, // 200 TL
  /** medianPriceCents < MID → ₺₺ (Orta), aksi hâlde → ₺₺₺ (Premium) */
  MID: 45000,    // 450 TL
} as const;

export type PriceLevel = '₺' | '₺₺' | '₺₺₺';

/**
 * medianPriceCents değerinden fiyat seviyesi döner.
 * null/undefined ise null döner → rozet gösterilmemeli.
 * 0 veya negatif değer de null döner (geçersiz fiyat verisi).
 */
export function getPriceLevel(medianPriceCents: number | null | undefined): PriceLevel | null {
  if (medianPriceCents == null || medianPriceCents <= 0) return null;
  if (medianPriceCents < PRICE_LEVEL_THRESHOLDS.BUDGET) return '₺';
  if (medianPriceCents < PRICE_LEVEL_THRESHOLDS.MID) return '₺₺';
  return '₺₺₺';
}

/**
 * Fiyat seviyesi için Tailwind renk sınıfı döner.
 * text-* sınıfı — arka plan rengi için bg-* varyantı gerekirse ayrıca eklenebilir.
 */
export function getPriceLevelClass(level: PriceLevel): string {
  switch (level) {
    case '₺':
      return 'text-emerald-600';
    case '₺₺':
      return 'text-amber-600';
    case '₺₺₺':
      return 'text-rose-600';
  }
}
