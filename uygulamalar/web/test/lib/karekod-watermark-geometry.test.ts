import QRCode from 'qrcode';
import { describe, expect, it } from 'vitest';
import {
  addSvgWatermark,
  QR_WATERMARK_PNG_BOTTOM_OFFSET_PX,
  QR_WATERMARK_PNG_FONT_DIVISOR,
  QR_WATERMARK_SVG_BOTTOM_OFFSET,
  QR_WATERMARK_SVG_FONT_SIZE,
} from '@/src/ui/bolumler/karekod-uretici';

// Free-tier karekodlarda gösterilen filigranin, QR'in kendi "quiet zone" (sessiz kenar)
// bandinin disina tasip gercek modullerle cakismadigini dogrular. karekod-uretici.tsx'teki
// addPngWatermark/addSvgWatermark, QR_WATERMARK_* sabitlerini kullanir; buradaki testler
// gercek `qrcode` paketinin urettigi modul sayisina gore geometriyi kontrol eder.
//
// Font metrikleri (ascent/descent orani) ortama gore degisebildigi icin, gercek bir
// font olcumune degil, gozlemlenenden daha KOTUMSER (buyuk) sabit oranlara dayanir —
// boylece test, gercek tarayicilarda daha da guvenli olan gercek degerlere gore
// yanlis-negatif vermez, ama bir regresyonu (font/offset degisikligini) yakalar.
const CONSERVATIVE_ASCENT_RATIO = 0.85;
const CONSERVATIVE_DESCENT_RATIO = 0.3;

const PNG_WIDTH = 1280;
const PNG_MARGIN_MODULES = 1;

function realisticUrls() {
  return {
    // /m/<uuid>?lang=tr&theme=photo-heavy — slug atanmamis isletme + en uzun tema anahtari.
    worstCase: 'https://www.yeedoy.com/m/1f8a3c2e-9b7d-4e21-8f3a-6c2d9e0b7a41?lang=tr&theme=photo-heavy',
    // /m/<slug>?lang=en&theme=modern-dark — tipik, slug atanmis isletme.
    typical: 'https://www.yeedoy.com/m/some-restaurant-name-slug-here?lang=en&theme=modern-dark',
    // /kod/<kisa-kod>?lang=tr — kisa link.
    short: 'https://www.yeedoy.com/kod/ab12cd?lang=tr',
  };
}

function moduleCount(url: string) {
  return QRCode.create(url, { errorCorrectionLevel: 'H' }).modules.size;
}

describe('karekod filigrani — PNG geometrisi (canvas.width / DIVISOR, canvas.height - OFFSET)', () => {
  it.each(Object.entries(realisticUrls()))('quiet zone icinde kalir: %s', (_label, url) => {
    const modules = moduleCount(url);
    const quietZonePx = PNG_WIDTH / (modules + 2 * PNG_MARGIN_MODULES);
    const fontSizePx = Math.round(PNG_WIDTH / QR_WATERMARK_PNG_FONT_DIVISOR);
    const ascent = fontSizePx * CONSERVATIVE_ASCENT_RATIO;
    const descent = fontSizePx * CONSERVATIVE_DESCENT_RATIO;

    const baselineY = PNG_WIDTH - QR_WATERMARK_PNG_BOTTOM_OFFSET_PX;
    const glyphTopY = baselineY - ascent;
    const glyphBottomY = baselineY + descent;
    const quietZoneTopY = PNG_WIDTH - quietZonePx;

    // Harfin tepesi, gercek QR modullerinin basladigi sinirin ALTINDA (yani sessiz
    // bolgenin icinde) kalmali — sinira essiz kalirsa cakisma riski dogar.
    expect(glyphTopY).toBeGreaterThan(quietZoneTopY);
    // Harfin alti (inici olan karakterler dahil) tuvalin disina tasmamali.
    expect(glyphBottomY).toBeLessThan(PNG_WIDTH);
  });

  it('eski (regresyon) degerleri bu testte basarisiz olurdu — kontrast icin', () => {
    const modules = moduleCount(realisticUrls().worstCase);
    const quietZonePx = PNG_WIDTH / (modules + 2 * PNG_MARGIN_MODULES);
    const OLD_DIVISOR = 26;
    const OLD_BOTTOM_OFFSET = 24;
    const fontSizePx = Math.round(PNG_WIDTH / OLD_DIVISOR);
    const ascent = fontSizePx * CONSERVATIVE_ASCENT_RATIO;
    const baselineY = PNG_WIDTH - OLD_BOTTOM_OFFSET;
    const glyphTopY = baselineY - ascent;
    const quietZoneTopY = PNG_WIDTH - quietZonePx;

    expect(glyphTopY).toBeLessThan(quietZoneTopY);
  });
});

describe('karekod filigrani — SVG geometrisi (viewBox birimi = 1 modul, margin = 1)', () => {
  it.each(Object.entries(realisticUrls()))('quiet zone icinde kalir: %s', async (_label, url) => {
    const rawSvg = await QRCode.toString(url, {
      errorCorrectionLevel: 'H',
      margin: PNG_MARGIN_MODULES,
      type: 'svg',
      color: { dark: '#7F1D1D', light: '#ffffff' },
    });

    const viewBoxMatch = rawSvg.match(/viewBox="0 0 [\d.]+ ([\d.]+)"/);
    expect(viewBoxMatch).not.toBeNull();
    const viewBoxHeight = Number(viewBoxMatch![1]);

    const watermarked = addSvgWatermark(rawSvg);
    const textMatch = watermarked.match(/<text x="50%" y="([\d.]+)"[^>]*font-size="([\d.]+)"/);
    expect(textMatch).not.toBeNull();
    const y = Number(textMatch![1]);
    const fontSize = Number(textMatch![2]);

    expect(fontSize).toBe(QR_WATERMARK_SVG_FONT_SIZE);
    expect(y).toBeCloseTo(viewBoxHeight - QR_WATERMARK_SVG_BOTTOM_OFFSET, 5);

    const ascent = fontSize * CONSERVATIVE_ASCENT_RATIO;
    const descent = fontSize * CONSERVATIVE_DESCENT_RATIO;
    const glyphTop = y - ascent;
    const glyphBottom = y + descent;
    const quietZoneTop = viewBoxHeight - PNG_MARGIN_MODULES;

    expect(glyphTop).toBeGreaterThan(quietZoneTop);
    expect(glyphBottom).toBeLessThan(viewBoxHeight);
  });

  it('filigran her zaman tam olarak bir <text> etiketi olarak eklenir', async () => {
    const rawSvg = await QRCode.toString(realisticUrls().typical, {
      errorCorrectionLevel: 'H',
      margin: PNG_MARGIN_MODULES,
      type: 'svg',
    });
    const watermarked = addSvgWatermark(rawSvg);

    expect(watermarked.match(/<text/g)).toHaveLength(1);
    expect(watermarked).toContain('</text></svg>');
  });
});
