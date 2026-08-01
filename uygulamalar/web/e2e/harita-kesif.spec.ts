import { expect, test } from '@playwright/test';
import type { HaritaIsletme } from '../src/lib/veri/harita-okuma';

function syntheticBusiness(i: number): HaritaIsletme {
  return {
    id: `synthetic-${i}`,
    name: `Test İşletme ${i}`,
    slug: `test-isletme-${i}`,
    category: 'Kafe',
    lat: 39.925 + i * 0.0005,
    lng: 32.866 + i * 0.0005,
    avg_rating: 4.2,
    logo_url: null,
    cover_url: null,
    is_verified: false,
  };
}

test.describe('Keşif haritası — pin clustering', () => {
  test('yoğun bölgede tekil pin yerine küme balonu gösterir ve tıklayınca yakınlaştırır', async ({ page }) => {
    test.slow();
    const businesses = Array.from({ length: 30 }, (_, i) => syntheticBusiness(i));

    await page.route('**/api/harita-isletmeler*', (route) => route.fulfill({ json: businesses }));

    await page.goto('/kesif/harita');
    await page.waitForSelector('.maplibregl-canvas');

    // moveend tetikleyip mock veriyi çektirmek için zoom kontrolüne tıkla
    await page.click('.maplibregl-ctrl-zoom-in');
    await page.waitForTimeout(1500); // 500ms fetch debounce + network + render

    const clusterBadges = page.locator('[data-testid="harita-cluster"]');
    const richPins = page.locator('[data-testid="harita-pin"]');

    await expect(clusterBadges.first()).toBeVisible();
    const richPinCountBefore = await richPins.count();
    expect(richPinCountBefore).toBeLessThan(businesses.length);

    await clusterBadges.first().click();
    await page.waitForTimeout(1500); // flyTo (500ms) + yeniden render

    const richPinCountAfter = await richPins.count();
    expect(richPinCountAfter).toBeGreaterThan(richPinCountBefore);
  });
});
