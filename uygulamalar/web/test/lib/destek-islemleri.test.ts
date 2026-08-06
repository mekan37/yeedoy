import { describe, it, expect } from 'vitest';
import {
  destekTalebiOlustur,
  destekTalebiListele,
  destekTalebiDetay,
  destekMesajGonder,
} from '@/app/sahip/destek/destek-islemleri';

describe('destek server action\'ları', () => {
  it('fonksiyonlar export edilir', () => {
    expect(typeof destekTalebiOlustur).toBe('function');
    expect(typeof destekTalebiListele).toBe('function');
    expect(typeof destekTalebiDetay).toBe('function');
    expect(typeof destekMesajGonder).toBe('function');
  });
});
