import { describe, expect, it } from 'vitest';
import * as medyaAdresi from '@/src/lib/medya-adresi';

type AnaGorselOlusturucu = (
  coverUrl: string | null,
  logoUrl: string | null,
  options?: { width?: number; quality?: number },
) => string | null;

const anaGorselOlusturucu = Reflect.get(medyaAdresi, 'buildBusinessHeroImageUrl') as AnaGorselOlusturucu | undefined;

describe('işletme ana görseli', () => {
  it('kapak yoksa işletme logosunu gösterir', () => {
    expect(anaGorselOlusturucu?.(
      null,
      'https://i.hizliresim.com/lntzmyzu.jpg',
      { width: 1200, quality: 85 },
    )).toBe('https://i.hizliresim.com/lntzmyzu.jpg');
  });

  it('kapak varsa logodan önce kapağı kullanır', () => {
    expect(anaGorselOlusturucu?.(
      'https://i.hizliresim.com/kapak.jpg',
      'https://i.hizliresim.com/logo.jpg',
    )).toBe('https://i.hizliresim.com/kapak.jpg');
  });
});
