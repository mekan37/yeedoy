import { expect, test, type Page } from '@playwright/test';

// ─── Yardımcı ────────────────────────────────────────────────────────────────

async function getCssVar(page: Page, varName: string) {
  return page.evaluate(
    (name) => getComputedStyle(document.documentElement).getPropertyValue(name).trim(),
    varName,
  );
}

// ─── Testler ─────────────────────────────────────────────────────────────────

test.describe('Karanlık mod — ThemeToggle', () => {
  test.beforeEach(async ({ page }) => {
    // Her testten önce localStorage'ı temizle, light OS tercihiyle başla
    await page.emulateMedia({ colorScheme: 'light' });
    await page.goto('/');
    await page.evaluate(() => localStorage.removeItem('yd-theme'));
  });

  test('toggle butonu anasayfada görünür', async ({ page }) => {
    const toggle = page.getByRole('button', { name: /karanlık moda geç|açık moda geç/i });
    await expect(toggle).toBeVisible();
  });

  test('toggle tıklanınca html.dark class eklenir', async ({ page }) => {
    // Light OS → başlangıçta dark class yok
    const before = await page.evaluate(() => document.documentElement.classList.contains('dark'));
    expect(before).toBe(false);

    const toggle = page.getByRole('button', { name: /karanlık moda geç/i });
    await toggle.click();

    const after = await page.evaluate(() => document.documentElement.classList.contains('dark'));
    expect(after).toBe(true);
  });

  test('toggle iki kez tıklanınca light moduna döner', async ({ page }) => {
    const toggle = page.getByRole('button', { name: /karanlık moda geç/i });
    await toggle.click();
    // Şimdi dark modunda — buton etiketi değişti
    const toggleBack = page.getByRole('button', { name: /açık moda geç/i });
    await toggleBack.click();

    const hasDark = await page.evaluate(() => document.documentElement.classList.contains('dark'));
    const hasLight = await page.evaluate(() => document.documentElement.classList.contains('light'));
    expect(hasDark).toBe(false);
    expect(hasLight).toBe(true);
  });

  test('toggle localStorage\'a yd-theme yazar', async ({ page }) => {
    const toggle = page.getByRole('button', { name: /karanlık moda geç/i });
    await toggle.click();

    const stored = await page.evaluate(() => localStorage.getItem('yd-theme'));
    expect(stored).toBe('dark');
  });

  test('localStorage tercih sayfayı yeniden yüklemede korunur', async ({ page }) => {
    // Dark moda geç
    const toggle = page.getByRole('button', { name: /karanlık moda geç/i });
    await toggle.click();

    // Sayfayı yenile — flash-prevention script localStorage'ı okur
    await page.reload();

    const hasDark = await page.evaluate(() => document.documentElement.classList.contains('dark'));
    expect(hasDark).toBe(true);
  });
});

test.describe('Karanlık mod — CSS token değişkenleri', () => {
  test('light modda --yd-color-bg açık gri (#f9fafb)', async ({ page }) => {
    await page.emulateMedia({ colorScheme: 'light' });
    await page.goto('/');
    await page.evaluate(() => {
      localStorage.setItem('yd-theme', 'light');
      document.documentElement.classList.remove('dark');
      document.documentElement.classList.add('light');
    });

    const bg = await getCssVar(page, '--yd-color-bg');
    // Light: #f9fafb
    expect(bg.toLowerCase()).toBe('#f9fafb');
  });

  test('dark modda --yd-color-bg koyu lacivert (#0d0f13)', async ({ page }) => {
    await page.emulateMedia({ colorScheme: 'light' });
    await page.goto('/');
    await page.evaluate(() => {
      localStorage.setItem('yd-theme', 'dark');
      document.documentElement.classList.remove('light');
      document.documentElement.classList.add('dark');
    });
    // Stil yeniden hesaplanması için kısa bekle
    await page.waitForTimeout(50);

    const bg = await getCssVar(page, '--yd-color-bg');
    expect(bg.toLowerCase()).toBe('#0d0f13');
  });

  test('dark modda --yd-color-card koyu (#161a22)', async ({ page }) => {
    await page.emulateMedia({ colorScheme: 'light' });
    await page.goto('/');
    await page.evaluate(() => {
      document.documentElement.classList.remove('light');
      document.documentElement.classList.add('dark');
    });
    await page.waitForTimeout(50);

    const card = await getCssVar(page, '--yd-color-card');
    expect(card.toLowerCase()).toBe('#161a22');
  });
});

test.describe('Karanlık mod — OS tercih algılama', () => {
  test('OS dark tercihiyle sayfaya girilince html.dark uygulanır', async ({ page }) => {
    await page.emulateMedia({ colorScheme: 'dark' });
    // localStorage'da kayıt yok — flash-prevention OS'u okur
    await page.addInitScript(() => localStorage.removeItem('yd-theme'));
    await page.goto('/');

    const hasDark = await page.evaluate(() => document.documentElement.classList.contains('dark'));
    expect(hasDark).toBe(true);
  });

  test('localStorage=light ise OS dark tercihini geçersiz kılar', async ({ page }) => {
    await page.emulateMedia({ colorScheme: 'dark' });
    await page.addInitScript(() => localStorage.setItem('yd-theme', 'light'));
    await page.goto('/');

    const hasDark = await page.evaluate(() => document.documentElement.classList.contains('dark'));
    const hasLight = await page.evaluate(() => document.documentElement.classList.contains('light'));
    expect(hasDark).toBe(false);
    expect(hasLight).toBe(true);
  });
});

test.describe('Karanlık mod — kritik sayfalar erişilebilirlik', () => {
  const kritikSayfalar = ['/', '/giris', '/kesif'];

  for (const rota of kritikSayfalar) {
    test(`dark modda ${rota} sayfası render hatası vermez`, async ({ page }) => {
      await page.emulateMedia({ colorScheme: 'dark' });
      await page.addInitScript(() => localStorage.setItem('yd-theme', 'dark'));

      const hatalar: string[] = [];
      page.on('pageerror', (err) => hatalar.push(err.message));

      await page.goto(rota);
      await page.waitForLoadState('networkidle');

      expect(hatalar).toHaveLength(0);
    });
  }
});
