import { expect, test } from '@playwright/test';

test('home page renders public menu landing', async ({ page }) => {
  await page.goto('/');
  await expect(
    page.getByRole('heading', {
      name: 'Public menu and QR generation, without moving admin CRUD into Next.js.',
    }),
  ).toBeVisible();
  await expect(page.locator('p').filter({ hasText: /^\/m\/:publicSlugOrId$/ })).toBeVisible();
  await expect(page.locator('p').filter({ hasText: /^\/qr\/:businessId$/ })).toBeVisible();
});

test('qr route shows not found for an unknown business id', async ({ page }) => {
  await page.goto('/karekod/00000000-0000-4000-8000-000000000000');
  await expect(page.getByRole('heading', { name: /menu not found/i })).toBeVisible();
});

test('public menu route shows not found for an unknown slug', async ({ page }) => {
  const response = await page.goto('/m/this-slug-does-not-exist-at-all');
  expect(response?.status()).toBe(404);
});

test('login page with external redirect param falls back to safe internal path', async ({ page }) => {
  await page.goto('/login?redirect=https%3A%2F%2Fevil.example.com%2Fsteal');
  // sanitizeInternalRedirect rejects external URLs; login page should render without error
  await expect(page).toHaveURL('/login');
  await expect(page.locator('form')).toBeVisible();
});

test('login page with valid internal redirect preserves the redirect param', async ({ page }) => {
  await page.goto('/login?redirect=%2Fqr%2F00000000-0000-4000-a000-000000000001');
  await expect(page).toHaveURL(/\/login\?redirect=%2Fqr%2F/);
  await expect(page.locator('form')).toBeVisible();
});
