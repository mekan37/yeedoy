import { describe, it, expect } from 'vitest';
import { eslesmeYuzdesiHesapla } from '@/src/lib/oneri-eslesme';

describe('eslesmeYuzdesiHesapla', () => {
  it('tercih edilen kategoride, yüksek puanlı işletmeye yüksek skor verir', () => {
    const skor = eslesmeYuzdesiHesapla('Kafe', [{ category: 'Kafe', pct: 60 }], 4.8);
    expect(skor).toBeGreaterThanOrEqual(85);
    expect(skor).toBeLessThanOrEqual(99);
  });

  it('tercih listesinde olmayan kategoriye taban skor + puan bonusu verir', () => {
    const skor = eslesmeYuzdesiHesapla('Mekan', [{ category: 'Kafe', pct: 60 }], 3.0);
    expect(skor).toBe(70);
  });

  it('tercih/puan verisi yoksa taban skoru döner', () => {
    const skor = eslesmeYuzdesiHesapla(null, [], null);
    expect(skor).toBe(70);
  });

  it('skor her zaman 60-99 aralığında kalır', () => {
    const skor = eslesmeYuzdesiHesapla('Kafe', [{ category: 'Kafe', pct: 100 }], 5);
    expect(skor).toBeLessThanOrEqual(99);
  });
});
