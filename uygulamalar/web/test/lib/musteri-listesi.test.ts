import { describe, it, expect } from 'vitest';
import { MusteriListesi } from '@/app/sahip/musteriler/musteri-listesi';
import { ZamanCizelgesi } from '@/app/sahip/musteriler/[user_id]/zaman-cizelgesi';

describe('CRM müşteri bileşenleri', () => {
  it('bileşenler export edilir', () => {
    expect(typeof MusteriListesi).toBe('function');
    expect(typeof ZamanCizelgesi).toBe('function');
  });
});
