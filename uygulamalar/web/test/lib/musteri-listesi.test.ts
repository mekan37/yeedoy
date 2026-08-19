import { describe, it, expect } from 'vitest';
import { filtrelenmisMusteriler } from '@/app/sahip/musteriler/musteriler-yardimcilari';
import { type MusteriOzet } from '@/app/sahip/musteriler/musteriler-istemcisi';
import { ZamanCizelgesi } from '@/app/sahip/musteriler/[user_id]/zaman-cizelgesi';

describe('CRM müşteri bileşenleri', () => {
  it('bileşenler export edilir', () => {
    expect(typeof ZamanCizelgesi).toBe('function');
  });
});

function fakeMusteri(overrides: Partial<MusteriOzet>): MusteriOzet {
  return {
    user_id: 'u1',
    display_name: 'Test Müşteri',
    avatar_url: null,
    last_interaction_at: '2026-08-01T00:00:00Z',
    first_interaction_at: '2026-07-01T00:00:00Z',
    review_count: 0,
    reservation_count: 0,
    loyalty_progress: null,
    loyalty_reward_threshold: null,
    loyalty_event_count: 0,
    is_following: false,
    is_email_subscribed: false,
    tags: [],
    ...overrides,
  };
}

describe('filtrelenmisMusteriler', () => {
  const musteriler: MusteriOzet[] = [
    fakeMusteri({ user_id: 'u1', display_name: 'Ahmet Yılmaz' }),
    fakeMusteri({ user_id: 'u2', display_name: 'İstanbul Şube Müşterisi' }),
    fakeMusteri({ user_id: 'u3', display_name: 'Zeynep Kaya' }),
  ];

  it('boş arama metniyle tüm listeyi döner', () => {
    expect(filtrelenmisMusteriler(musteriler, '')).toEqual(musteriler);
  });

  it('eşleşen isimde tek sonuç döner', () => {
    const sonuc = filtrelenmisMusteriler(musteriler, 'Zeynep');
    expect(sonuc.map((m) => m.user_id)).toEqual(['u3']);
  });

  it('eşleşmeyen aramada boş dizi döner', () => {
    expect(filtrelenmisMusteriler(musteriler, 'Mehmet')).toEqual([]);
  });

  it('Türkçe büyük/küçük harf duyarlılığını doğru işler (İ/i)', () => {
    const sonuc = filtrelenmisMusteriler(musteriler, 'istanbul');
    expect(sonuc.map((m) => m.user_id)).toEqual(['u2']);
  });
});
