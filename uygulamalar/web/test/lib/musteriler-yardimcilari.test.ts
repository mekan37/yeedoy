import { describe, it, expect } from 'vitest';
import { zincirAciklamasiOlustur } from '@/app/sahip/musteriler/musteriler-yardimcilari';

describe('zincirAciklamasiOlustur', () => {
  it('zincirsizken temel açıklamayı döner', () => {
    expect(zincirAciklamasiOlustur(null)).toBe('İşletmenizle etkileşimi olan tüm müşterileri görüntüleyin ve analiz edin.');
  });

  it('zincir adı varsa zincir ibaresini ekler', () => {
    expect(zincirAciklamasiOlustur('Demo Zinciri')).toBe(
      'İşletmenizle etkileşimi olan tüm müşterileri görüntüleyin ve analiz edin. Zincir çapında • Demo Zinciri',
    );
  });
});
