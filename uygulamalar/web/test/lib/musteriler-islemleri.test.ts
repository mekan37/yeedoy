import { describe, it, expect } from 'vitest';
import { notEkle, etiketEkle, etiketSil } from '@/app/sahip/musteriler/musteriler-islemleri';

describe('CRM v2 müşteri not/etiket server action\'ları', () => {
  it('fonksiyonlar export edilir', () => {
    expect(typeof notEkle).toBe('function');
    expect(typeof etiketEkle).toBe('function');
    expect(typeof etiketSil).toBe('function');
  });

  it('notEkle boş not için hata döner', async () => {
    const result = await notEkle('11111111-1111-1111-1111-111111111111', '22222222-2222-2222-2222-222222222222', '');
    expect(result).toEqual({ error: 'Geçersiz form verisi' });
  });

  it('etiketEkle 40 karakterden uzun etiket için hata döner', async () => {
    const result = await etiketEkle(
      '11111111-1111-1111-1111-111111111111',
      '22222222-2222-2222-2222-222222222222',
      'a'.repeat(41),
    );
    expect(result).toEqual({ error: 'Geçersiz form verisi' });
  });

  it('etiketSil geçersiz tag_id için hata döner', async () => {
    const result = await etiketSil('not-a-uuid', '22222222-2222-2222-2222-222222222222');
    expect(result).toEqual({ error: 'Geçersiz parametre' });
  });
});
