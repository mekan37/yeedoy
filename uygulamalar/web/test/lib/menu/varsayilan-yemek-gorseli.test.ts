import { describe, expect, it } from 'vitest';
import { bulEslesenYemekGorselleri, bulVarsayilanYemekGorseli, type StockDishImage } from '@/src/lib/menu/varsayilan-yemek-gorseli';

const KUTUPHANE: StockDishImage[] = [
  { id: '1', image_url: 'https://x.test/corbalar/mercimek.webp', keywords: ['mercimek çorbası'] },
  { id: '2', image_url: 'https://x.test/sulu_yemekler/ali_nazik.webp', keywords: ['ali nazik'] },
  { id: '3', image_url: 'https://x.test/zeytinyaglilar/barbunya.webp', keywords: ['zeytinyağlı barbunya'] },
  { id: '4', image_url: 'https://x.test/sulu_yemekler/bamya.webp', keywords: ['etli bamya'] },
  { id: '5', image_url: 'https://x.test/corbalar/bamya.webp', keywords: ['bamya çorbası'] },
];

describe('bulVarsayilanYemekGorseli', () => {
  it('ürün adı bir anahtar ifadeyi içeriyorsa ilgili görseli döner', () => {
    expect(bulVarsayilanYemekGorseli('Mercimek Çorbası', KUTUPHANE)).toBe('https://x.test/corbalar/mercimek.webp');
  });

  it('bitişik yazılmış yemek adını da eşleştirir (ör. "Alinazik")', () => {
    expect(bulVarsayilanYemekGorseli('Alinazik Kebap', KUTUPHANE)).toBe('https://x.test/sulu_yemekler/ali_nazik.webp');
  });

  it('aynı kelime birden fazla görselde geçerse en uzun/özgül anahtar kazanır', () => {
    // "Etli Bamya Çorbası" hem "etli bamya" (11 char) hem "bamya çorbası" (13 char)
    // ile eşleşir — daha uzun/özgül olan kazanmalı.
    expect(bulVarsayilanYemekGorseli('Etli Bamya Çorbası', KUTUPHANE)).toBe('https://x.test/corbalar/bamya.webp');
  });

  it('hiçbir anahtar ifade eşleşmiyorsa null döner', () => {
    expect(bulVarsayilanYemekGorseli('Cheeseburger', KUTUPHANE)).toBeNull();
  });

  it('boş kütüphaneyle null döner (hata fırlatmaz)', () => {
    expect(bulVarsayilanYemekGorseli('Mercimek Çorbası', [])).toBeNull();
  });
});

describe('bulEslesenYemekGorselleri', () => {
  it('birden fazla eşleşmeyi en özgülden en genele sıralı döner', () => {
    const sonuc = bulEslesenYemekGorselleri('Etli Bamya Çorbası', KUTUPHANE);
    expect(sonuc.map((s) => s.id)).toEqual(['5', '4']);
  });

  it('eşleşme yoksa boş dizi döner', () => {
    expect(bulEslesenYemekGorselleri('Cheeseburger', KUTUPHANE)).toEqual([]);
  });
});
