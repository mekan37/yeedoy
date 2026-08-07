import { describe, it, expect } from 'vitest';
import {
  subeYonetimVerisiGetir,
  zincirOlustur,
  subeEkle,
  subeCikar,
  subeSirasiGuncelle,
  eklenebilirIsletmeleriListele,
} from '@/app/sahip/coklu-sube/coklu-sube-islemleri';

describe('çoklu şube server action\'ları', () => {
  it('fonksiyonlar export edilir', () => {
    expect(typeof subeYonetimVerisiGetir).toBe('function');
    expect(typeof zincirOlustur).toBe('function');
    expect(typeof subeEkle).toBe('function');
    expect(typeof subeCikar).toBe('function');
    expect(typeof subeSirasiGuncelle).toBe('function');
    expect(typeof eklenebilirIsletmeleriListele).toBe('function');
  });
});
