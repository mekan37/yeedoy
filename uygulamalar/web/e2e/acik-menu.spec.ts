import { expect, test } from '@playwright/test';

test('anasayfa acik menu girisini gosterir', async ({ page }) => {
  await page.goto('/');
  await expect(
    page.getByRole('heading', {
      name: 'Yakınındaki lezzetleri keşfet',
    }),
  ).toBeVisible();
  await expect(page.locator('p').filter({ hasText: /^\/m\/:publicSlugOrId$/ })).toBeVisible();
  await expect(page.locator('p').filter({ hasText: /^\/karekod\/:businessId$/ })).toBeVisible();
});

test('karekod rotasi bilinmeyen isletme icin bulunamadi gosterir', async ({ page }) => {
  await page.goto('/karekod/00000000-0000-4000-8000-000000000000');
  await expect(page.getByRole('heading', { name: /menu bulunamadi/i })).toBeVisible();
});

test('acik menu rotasi bilinmeyen slug icin bulunamadi dondurur', async ({ page }) => {
  const response = await page.goto('/m/this-slug-does-not-exist-at-all');
  expect(response?.status()).toBe(404);
});

test('giris sayfasi dis yonlendirmeyi guvenli ic yola dondurur', async ({ page }) => {
  await page.goto('/giris?redirect=https%3A%2F%2Fevil.example.com%2Fsteal');
  await expect(page).toHaveURL('/giris');
  await expect(page.locator('form')).toBeVisible();
});

test('giris sayfasi gecerli ic yonlendirmeyi korur', async ({ page }) => {
  await page.goto('/giris?redirect=%2Fkarekod%2F00000000-0000-4000-a000-000000000001');
  await expect(page).toHaveURL(/\/giris\?redirect=%2Fkarekod%2F/);
  await expect(page.locator('form')).toBeVisible();
});
