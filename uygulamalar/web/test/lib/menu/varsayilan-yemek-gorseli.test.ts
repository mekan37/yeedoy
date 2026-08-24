import { beforeAll, describe, expect, it } from 'vitest';
import { bulVarsayilanYemekGorseli } from '@/src/lib/menu/varsayilan-yemek-gorseli';

describe('bulVarsayilanYemekGorseli', () => {
  beforeAll(() => {
    process.env.NEXT_PUBLIC_SUPABASE_URL ??= 'https://test.supabase.co';
  });

  it('kategori çorba ise ürün adına göre çorba görseli döner', () => {
    const url = bulVarsayilanYemekGorseli('Mercimek Çorbası', 'Çorbalar');
    expect(url).toContain('varsayilan-yemekler/corbalar/mercimek.webp');
  });

  it('bitişik yazılmış yemek adını da eşleştirir (ör. "Alinazik")', () => {
    const url = bulVarsayilanYemekGorseli('Alinazik Kebap', 'Ana Yemekler');
    expect(url).toContain('varsayilan-yemekler/sulu_yemekler/ali_nazik.webp');
  });

  it('aynı slug birden fazla klasörde varsa kategoriye göre doğru klasörü seçer', () => {
    const zeytinyagli = bulVarsayilanYemekGorseli('Zeytinyağlı Barbunya', 'Zeytinyağlılar');
    expect(zeytinyagli).toContain('varsayilan-yemekler/zeytinyaglilar/barbunya.webp');

    const suluYemek = bulVarsayilanYemekGorseli('Etli Bamya', 'Ana Yemekler');
    expect(suluYemek).toContain('varsayilan-yemekler/sulu_yemekler/bamya.webp');
  });

  it('kategori 4 kapsanan gruptan birine eşleşmiyorsa null döner', () => {
    expect(bulVarsayilanYemekGorseli('Cheeseburger', 'Burgerler')).toBeNull();
  });

  it('kategori kapsanan gruptaysa ama ürün adı hiçbir yemekle örtüşmüyorsa null döner', () => {
    expect(bulVarsayilanYemekGorseli('Bilinmeyen Özel Yemek', 'Çorbalar')).toBeNull();
  });

  it('kategori adı boş/yoksa null döner', () => {
    expect(bulVarsayilanYemekGorseli('Mercimek Çorbası', null)).toBeNull();
    expect(bulVarsayilanYemekGorseli('Mercimek Çorbası', undefined)).toBeNull();
  });

  it('dönen URL Supabase Storage public path formatındadır', () => {
    const url = bulVarsayilanYemekGorseli('Humus', 'Salata & Mezeler');
    expect(url).toMatch(/^https:\/\/.*\/storage\/v1\/object\/public\/menu-media\/varsayilan-yemekler\/.*\.webp$/);
  });
});
