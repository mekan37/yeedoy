import { describe, it, expect } from 'vitest';
import {
  formatPrice,
  computeStats,
  filterItems,
  sortItems,
  type Item,
  type Section,
} from '@/app/sahip/menuler/[menuId]/duzenle/menu-duzenleyici-yardimcilari';

const SECTIONS: Section[] = [
  { id: 's1', title: 'Kahvaltı', sort_order: 0 },
  { id: 's2', title: 'İçecekler', sort_order: 1 },
];

const ITEMS: Item[] = [
  {
    id: 'i1', name: 'Serpme Kahvaltı', description: null, image_url: null,
    price_cents: 29500, currency: 'TRY', is_available: true, section_id: 's1',
    sort_order: 0, calories_min: null, calories_max: null, calorie_source: null, portion_size: null, portion_unit: null,
    updated_at: '2026-07-06T09:40:00Z',
  },
  {
    id: 'i2', name: 'Flat White', description: null, image_url: null,
    price_cents: 9500, currency: 'TRY', is_available: false, section_id: 's2',
    sort_order: 0, calories_min: null, calories_max: null, calorie_source: null, portion_size: null, portion_unit: null,
    updated_at: '2026-07-04T16:22:00Z',
  },
  {
    id: 'i3', name: 'Soğuk Kahve', description: null, image_url: null,
    price_cents: 11000, currency: 'TRY', is_available: true, section_id: 's2',
    sort_order: 1, calories_min: null, calories_max: null, calorie_source: null, portion_size: null, portion_unit: null,
    updated_at: '2026-07-08T12:30:00Z',
  },
];

describe('formatPrice', () => {
  it('kuruşu TL string olarak biçimlendirir', () => {
    expect(formatPrice(9500)).toBe('95,00 ₺');
  });
});

describe('computeStats', () => {
  it('kategori/ürün/aktif/pasif sayılarını ve en son güncelleme tarihini hesaplar', () => {
    const stats = computeStats(SECTIONS, ITEMS);
    expect(stats.toplamKategori).toBe(2);
    expect(stats.toplamUrun).toBe(3);
    expect(stats.aktifUrun).toBe(2);
    expect(stats.pasifUrun).toBe(1);
    expect(stats.sonGuncelleme).toBe('2026-07-08T12:30:00Z');
  });

  it('ürün yokken sonGuncelleme null döner', () => {
    const stats = computeStats(SECTIONS, []);
    expect(stats.sonGuncelleme).toBeNull();
  });
});

describe('filterItems', () => {
  it('arama metnine göre ada/açıklamaya göre filtreler (case-insensitive)', () => {
    const result = filterItems(ITEMS, { search: 'kahv', sectionId: null, status: 'all' });
    expect(result.map((i) => i.id).sort()).toEqual(['i1', 'i3']);
  });

  it('kategoriye göre filtreler', () => {
    const result = filterItems(ITEMS, { search: '', sectionId: 's2', status: 'all' });
    expect(result.map((i) => i.id).sort()).toEqual(['i2', 'i3']);
  });

  it('duruma göre filtreler', () => {
    const result = filterItems(ITEMS, { search: '', sectionId: null, status: 'active' });
    expect(result.map((i) => i.id).sort()).toEqual(['i1', 'i3']);
  });

  it('filtreler birlikte AND mantığıyla uygulanır', () => {
    const result = filterItems(ITEMS, { search: '', sectionId: 's2', status: 'passive' });
    expect(result.map((i) => i.id)).toEqual(['i2']);
  });
});

describe('sortItems', () => {
  it('manuel modda sort_order sırasını korur', () => {
    const result = sortItems(ITEMS, 'manual');
    expect(result.map((i) => i.id)).toEqual(['i1', 'i2', 'i3']);
  });

  it('isme göre alfabetik sıralar', () => {
    const result = sortItems(ITEMS, 'name');
    expect(result.map((i) => i.id)).toEqual(['i2', 'i1', 'i3']);
  });

  it('fiyata göre artan sıralar', () => {
    const result = sortItems(ITEMS, 'price');
    expect(result.map((i) => i.id)).toEqual(['i2', 'i3', 'i1']);
  });

  it('son güncellemeye göre en yeni önce sıralar', () => {
    const result = sortItems(ITEMS, 'updated');
    expect(result.map((i) => i.id)).toEqual(['i3', 'i1', 'i2']);
  });
});
