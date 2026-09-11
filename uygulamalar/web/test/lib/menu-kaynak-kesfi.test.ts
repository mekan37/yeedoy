import { describe, expect, it } from 'vitest';
import {
  discoveryOutcomeMessage,
  normalizeExtractResult,
  parseDiscoveryOutcome,
} from '@/app/yonetici/isletmeler/[id]/menu-analiz/menu-analiz-yardimcilari';

describe('normalizeExtractResult', () => {
  it('complete discovery kalemini kuruşa ve kaynak bilgileriyle dönüştürür', () => {
    expect(normalizeExtractResult({
      outcome_status: 'SOURCE_FOUND_ITEMS_FOUND',
      source_provider: 'MenumGelsin',
      selected_source: 'https://menumgelsin.com/ornek/menulerim',
      items: [{
        name: 'KARIŞIK TOST',
        price: 190,
        currency: 'TRY',
        completeness: 'complete',
        price_missing: false,
      }],
    })).toEqual([expect.objectContaining({
      name: 'KARIŞIK TOST',
      price_cents: 19000,
      currency: 'TRY',
      requires_review: false,
      source_url: 'https://menumgelsin.com/ornek/menulerim',
      source_provider: 'MenumGelsin',
    })]);
  });

  it('partial kalemde price=null değerini sıfıra çevirmeden korur', () => {
    const [item] = normalizeExtractResult({
      source_url: 'https://ornek-restoran.com/menu',
      discovered_via: 'website_link',
      items: [{
        name: 'HUMUS',
        price: null,
        currency: null,
        completeness: 'partial',
        price_missing: true,
      }],
    });

    expect(item).toEqual(expect.objectContaining({
      name: 'HUMUS',
      price_cents: null,
      requires_review: true,
      source_url: 'https://ornek-restoran.com/menu',
      discovered_via: 'website_link',
    }));
    expect(item.review_reasons).toContain('Fiyat eksik');
  });

  it('canlı source-discovery şemasındaki extraction_result.result.categories öğelerini normalize eder', () => {
    const items = normalizeExtractResult({
      selected_source: 'https://menumgelsin.com/visalcafe/menuler',
      selected_source_provider: 'menumgelsin',
      extraction_started: true,
      extraction_finished: true,
      extracted_item_count: 4,
      outcome_status: 'SOURCE_FOUND_ITEMS_FOUND',
      extraction_result: {
        source: { requested_url: 'https://menumgelsin.com/visalcafe/menuler' },
        source_type: 'html',
        content_type: 'text/html',
        result: {
          category_count: 2,
          item_count: 4,
          categories: [
            {
              name: 'MAKARNALAR',
              items: [
                { name: 'PENNE PESTO', price: 250, currency: 'TRY', completeness: 'complete', price_missing: false },
                { name: 'KÖRİ SOSLU PENNE', price: 250, currency: 'TRY', completeness: 'complete', price_missing: false },
              ],
            },
            {
              name: 'TOSTLAR',
              items: [
                { name: 'KARIŞIK TOST', price: 190, currency: 'TRY', completeness: 'complete', price_missing: false },
                { name: 'KAŞARLI TOST', price: 180, currency: 'TRY', completeness: 'complete', price_missing: false },
              ],
            },
          ],
        },
      },
    });

    expect(items).toHaveLength(4);
    expect(items).toEqual(expect.arrayContaining([
      expect.objectContaining({ category_name: 'MAKARNALAR', name: 'PENNE PESTO', price_cents: 25000 }),
      expect.objectContaining({ category_name: 'TOSTLAR', name: 'KARIŞIK TOST', price_cents: 19000 }),
      expect.objectContaining({ category_name: 'TOSTLAR', name: 'KAŞARLI TOST', price_cents: 18000 }),
    ]));
    expect(items.every((item) => item.source_provider === 'menumgelsin')).toBe(true);
  });
});

describe('parseDiscoveryOutcome', () => {
  it.each([
    ['SOURCE_FOUND_ITEMS_FOUND', 'Menü bulundu ve analiz edildi.'],
    ['SOURCE_FOUND_PARTIAL_ITEMS', 'Menü bulundu. Bazı ürünlerin fiyat bilgisi eksik.'],
    ['SOURCE_FOUND_NO_ITEMS', 'Menü kaynağı bulundu ancak ürünler otomatik olarak okunamadı.'],
    ['SOURCE_FOUND_NEEDS_OCR', 'Menü bulundu ancak belge görüntü tabanlı olduğu için ek işleme gerekiyor.'],
    ['INVALID_SOURCE_CONTENT', 'Bulunan menü bağlantısı artık geçerli görünmüyor.'],
    ['NO_SOURCE_FOUND', 'İşletmenin web sitesinde otomatik olarak menü kaynağı bulunamadı.'],
    ['FETCH_FAILED', 'İşletmenin web sitesine otomatik olarak erişilemedi.'],
  ] as const)('%s teknik değerini kullanıcı metnine çevirir', (status, message) => {
    expect(parseDiscoveryOutcome({ outcome_status: status })?.message).toBe(message);
  });

  it('ürün, fiyat, kategori ve sağlayıcı özetini gerçek sonuçtan hesaplar', () => {
    expect(parseDiscoveryOutcome({
      outcome_status: 'SOURCE_FOUND_PARTIAL_ITEMS',
      source_provider: 'MenumGelsin',
      items: [
        { name: 'Tost', price: 190, category: 'Tostlar' },
        { name: 'Humus', price: null, category: 'Mezeler' },
      ],
    })).toEqual(expect.objectContaining({
      totalItems: 2,
      pricedItems: 1,
      missingPriceItems: 1,
      categoryCount: 2,
      sourceProvider: 'MenumGelsin',
    }));
  });

  it('failed job içindeki teknik outcome enum değerini kullanıcı metnine çevirir', () => {
    expect(discoveryOutcomeMessage('FETCH_FAILED')).toBe('İşletmenin web sitesine otomatik olarak erişilemedi.');
    expect(discoveryOutcomeMessage('unknown extractor failure')).toBeNull();
  });
});
