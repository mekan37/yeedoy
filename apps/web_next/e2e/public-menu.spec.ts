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
  await page.goto('/qr/00000000-0000-4000-8000-000000000000');
  await expect(page.getByRole('heading', { name: /menu not found/i })).toBeVisible();
});
