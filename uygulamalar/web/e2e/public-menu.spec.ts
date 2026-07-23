import { expect, test } from '@playwright/test';

test('home page renders public menu landing', async ({ page }) => {
  await page.goto('/');
  await expect(
    page.getByRole('heading', { name: /lezzetleri keşfet/i }),
  ).toBeVisible();
});

test('qr route shows not found for an unknown business id', async ({ page }) => {
  await page.goto('/karekod/00000000-0000-4000-8000-000000000000');
  await expect(page.getByRole('heading', { name: /sayfa bulunamadı/i })).toBeVisible();
});

test('public menu route shows not found for an unknown slug', async ({ page }) => {
  const response = await page.goto('/m/this-slug-does-not-exist-at-all');
  expect(response?.status()).toBe(404);
});

test('login page with external redirect param falls back to safe internal path', async ({ page }) => {
  await page.goto('/login?redirect=https%3A%2F%2Fevil.example.com%2Fsteal');
  // /login redirects to the canonical /giris; sanitizeInternalRedirect rejects
  // external URLs there, so the login page should still render without error
  await expect(page).toHaveURL(/\/giris/);
  await expect(page.locator('form')).toBeVisible();
});

test('login page with valid internal redirect preserves the redirect param', async ({ page }) => {
  await page.goto('/login?redirect=%2Fkarekod%2F00000000-0000-4000-a000-000000000001');
  await expect(page).toHaveURL(/\/giris\?redirect=%2Fkarekod%2F/);
  await expect(page.locator('form')).toBeVisible();
});
