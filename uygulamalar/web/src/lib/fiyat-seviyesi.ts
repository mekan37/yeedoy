/**
 * Fiyat seviyesi rozeti için tek eşik kaynağı.
 *
 * Öncelik sırası:
 *   1. businesses.price_level DB sütunu ('budget' | 'mid' | 'premium') — PR #15 ile eklendi.
 *   2. medianPriceCents eşik hesabı (fallback — DB sütunu NULL ise devreye girer).
 *   3. Her ikisi de NULL → rozet gizlenir.
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
 * Fiyat seviyesinin kaynağını belirtir.
 * 'db'       — businesses.price_level sütunundan geldi (daha güvenilir).
 * 'computed' — medianPriceCents eşik hesabından türetildi (fallback).
 * null       — kaynak yok, rozet gösterilmemeli.
 */
export type PriceLevelSource = 'db' | 'computed' | null;

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
 * businesses.price_level DB sütununu önce dener; NULL ise medianPriceCents'e düşer.
 *
 * Kullanım:
 *   const { level } = getPriceLevelFromBusiness(business.priceLevel, business.medianPriceCents);
 *   // level null ise rozet gösterme.
 */
export function getPriceLevelFromBusiness(
  priceLevelDb: string | null | undefined,
  medianPriceCents: number | null | undefined,
): { level: PriceLevel | null; source: PriceLevelSource } {
  if (priceLevelDb === 'budget') return { level: '₺', source: 'db' };
  if (priceLevelDb === 'mid') return { level: '₺₺', source: 'db' };
  if (priceLevelDb === 'premium') return { level: '₺₺₺', source: 'db' };

  const level = getPriceLevel(medianPriceCents);
  return { level, source: level != null ? 'computed' : null };
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
