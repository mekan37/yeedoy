import { describe, it, expect } from 'vitest';
import {
  programOlustur,
  programAktiflikDegistir,
  programGuncelle,
  programSil,
  qrOkut,
  odulKullan,
} from '@/app/sahip/pazarlama/sadakat/sadakat-islemleri';

describe('sadakat server action\'ları', () => {
  it('fonksiyonlar export edilir', () => {
    expect(typeof programOlustur).toBe('function');
    expect(typeof programAktiflikDegistir).toBe('function');
    expect(typeof programGuncelle).toBe('function');
    expect(typeof programSil).toBe('function');
    expect(typeof qrOkut).toBe('function');
    expect(typeof odulKullan).toBe('function');
  });

  it('qrOkut geçersiz UUID için hata döner', async () => {
    const result = await qrOkut('not-a-uuid', 'also-not-a-uuid');
    expect(result).toEqual({ error: 'Geçersiz QR içeriği' });
  });

  it('programGuncelle boş ad için hata döner', async () => {
    const result = await programGuncelle(
      '11111111-1111-1111-1111-111111111111',
      '',
      'ödül açıklaması',
      10,
    );
    expect(result).toEqual({ error: 'Geçersiz form verisi' });
  });

  it('programGuncelle aralık dışı reward_threshold için hata döner', async () => {
    const result = await programGuncelle(
      '11111111-1111-1111-1111-111111111111',
      'Program Adı',
      'ödül açıklaması',
      5000,
    );
    expect(result).toEqual({ error: 'Geçersiz form verisi' });
  });

  it('programSil geçersiz program_id için hata döner', async () => {
    const result = await programSil('not-a-uuid');
    expect(result).toEqual({ error: 'Geçersiz parametre' });
  });
});
